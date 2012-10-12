#!/usr/bin/perl
# graphviz plugin for ikiwiki: render graphviz source as an image.
# Josh Triplett
package IkiWiki::Plugin::graphviz;

use warnings;
use strict;
use IkiWiki 3.00;
use IPC::Open2;

sub import {
	hook(type => "getsetup", id => "graphviz", call => \&getsetup);
	hook(type => "needsbuild", id => "version", call => \&needsbuild);
	hook(type => "preprocess", id => "graph", call => \&graph, scan => 1);
}

sub getsetup () {
	return
		plugin => {
			safe => 1,
			rebuild => undef,
			section => "widget",
		},
}

my %graphviz_programs = (
	"dot" => 1, "neato" => 1, "fdp" => 1, "twopi" => 1, "circo" => 1
);

sub needsbuild {
	my $needsbuild=shift;
	foreach my $page (keys %pagestate) {
		if (exists $pagestate{$page}{graph} &&
		    exists $pagesources{$page} &&
		    grep { $_ eq $pagesources{$page} } @$needsbuild) {
			# remove state, will be re-added if
			# the graph is still there during the rebuild
			delete $pagestate{$page}{graph};
		}
	}       
	return $needsbuild;
}

sub render_graph (\%) {
	my %params = %{(shift)};
	
	my $src = "charset=\"utf-8\";\n";
	$src .= "ratio=compress;\nsize=\"".($params{width}+0).", ".($params{height}+0)."\";\n"
		if defined $params{width} and defined $params{height};
	$src .= $params{src};
	$src .= "}\n";
	
	# Use the sha1 of the graphviz code as part of its filename,
	# and as a unique identifier for its imagemap.
	eval q{use Digest::SHA};
	error($@) if $@;
	my $sha=IkiWiki::possibly_foolish_untaint(Digest::SHA::sha1_hex($params{type}.$src));
	$src = "$params{type} graph$sha {\n".$src;

	my $dest=$params{page}."/graph-".$sha.".png";
	will_render($params{page}, $dest);

	my $map=$pagestate{$params{destpage}}{graph}{$sha};
	if (! -e "$config{destdir}/$dest" || ! defined $map) {
		# Use ikiwiki's function to create the image file, this makes
		# sure needed subdirs are there and does some sanity checking.
		writefile($dest, $config{destdir}, "");
		
		my $pid;
		my $sigpipe=0;
		$SIG{PIPE}=sub { $sigpipe=1 };
		$pid=open2(*IN, *OUT, "$params{prog} -Tpng -o '$config{destdir}/$dest' -Tcmapx");

		# open2 doesn't respect "use open ':utf8'"
		binmode (IN, ':utf8');
		binmode (OUT, ':utf8');

		print OUT $src;
		close OUT;

		local $/ = undef;
		$map=$pagestate{$params{destpage}}{graph}{$sha}=<IN>;
		close IN;

		waitpid $pid, 0;
		$SIG{PIPE}="DEFAULT";
		error gettext("failed to run graphviz") if ($sigpipe || $?);
	}

	return "<img src=\"".urlto($dest, $params{destpage}).
		"\" usemap=\"#graph$sha\" />\n".
		$map;
}

sub graph (@) {
	my %params=@_;

	# Support wikilinks in the graph source.
	my $src=$params{src};
	$src="" unless defined $src;
	$src=IkiWiki::linkify($params{page}, $params{destpage}, $params{src});
	return unless defined wantarray; # scan mode short-circuit
	if ($src ne $params{src}) {
		# linkify makes html links, but graphviz wants plain
		# urls. This is, frankly a hack: Process source as html,
		# throw out everything inside tags that is not a href.
		my $s;
		my $nested=0;
		use HTML::Parser;
		error $@ if $@;
		my $p=HTML::Parser->new(api_version => 3);
		$p->handler(start => sub {
			my %attrs=%{shift()};
			if (exists $attrs{href}) {
				if ($s=~/href\s*=\s*"$/) {
					$s.=$attrs{href};
				}
				elsif ($s=~/href\s*=\s*$/) {
					$s.="\"$attrs{href}\"";
				}
				else {
					$s.="href=\"$attrs{href}\"";
				}
			}
			$nested++;
		}, "attr");
		$p->handler(end => sub {
			$nested--;
		});
		$p->handler(default => sub {
			$s.=join("", @_) unless $nested;
		}, "text");
		$p->parse($src);
		$p->eof;
		$s=~s/\[ href= \]//g; # handle self-links
		$params{src}=$s;
	}
	else {
		$params{src}=$src;
	}

	$params{type} = "digraph" unless defined $params{type};
	$params{prog} = "dot" unless defined $params{prog};
	error gettext("prog not a valid graphviz program") unless $graphviz_programs{$params{prog}};

	return render_graph(%params);
}

1
