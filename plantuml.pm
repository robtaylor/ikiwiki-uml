#!/usr/bin/perl
# plantuml for ikiwiki: render plantuml source as an image.
# Rob Taylor, based off graphviz plugin by Josh Triplett
package IkiWiki::Plugin::plantuml;

use warnings;
use strict;
use IkiWiki 3.00;
use IPC::Open2;
use File::Basename;

sub import {
	hook(type => "getsetup", id => "plantuml", call => \&getsetup);
	hook(type => "needsbuild", id => "version", call => \&needsbuild);
	hook(type => "preprocess", id => "uml", call => \&uml, scan => 1);
}

sub getsetup () {
	return
		plugin => {
			safe => 1,
			rebuild => undef,
			section => "widget",
		},
}


sub needsbuild {
	my $needsbuild=shift;
	foreach my $page (keys %pagestate) {
		if (exists $pagestate{$page}{uml} &&
		    exists $pagesources{$page} &&
		    grep { $_ eq $pagesources{$page} } @$needsbuild) {
			# remove state, will be re-added if
			# the uml is still there during the rebuild
			delete $pagestate{$page}{uml};
		}
	}       
	return $needsbuild;
}

sub render_uml (\%) {
	my %params = %{(shift)};
	
	my $src = $params{src};
	
	# Use the sha1 of the graphviz code as part of its filename,
	eval q{use Digest::SHA};
	error($@) if $@;
	my $sha=IkiWiki::possibly_foolish_untaint(Digest::SHA::sha1_hex($src));

	my $dest=$params{page}."/uml-".$sha.".png";
	will_render($params{page}, $dest);
	
        $src = "\@startuml\n".
	       "\'".urlto($dest, $params{destpage}).
	       $src.
	       "\@enduml\n";

	print $src;
	print $config{destdir}."\n";
	print "$config{destdir}/$dest"."\n";
        
	print "jar $params{jar}";		

	if (! -e "$config{destdir}/$dest") {
		print "STOADT\n";
		# Use ikiwiki's function to create the image file, this makes
		# sure needed subdirs are there and does some sanity checking.
		writefile($dest, $config{destdir}, "");

		print "jar $params{jar}";		
		my $pid;
		my $sigpipe=0;
		$SIG{PIPE}=sub { $sigpipe=1 };
		$pid=open2(*IN, *OUT, "java -jar $params{jar} -charset UTF-8 -pipe > '$config{destdir}/$dest'");

		# open2 doesn't respect "use open ':utf8'"
		binmode (IN, ':utf8');
		binmode (OUT, ':utf8');

		print OUT $src;
		close OUT;

		close IN;

		waitpid $pid, 0;
		$SIG{PIPE}="DEFAULT";
		error gettext("failed to run java -jar $params{jar}") if ($sigpipe || $?);
	}

	return "<img src=\"".urlto($dest, $params{destpage}).
		"\" />\n";
}

sub uml (@) {
	my %params=@_;
	my $key;

	print "src = " . $params{src};
	$params{jar}=dirname($INC{"IkiWiki/Plugin/plantuml.pm"})."/plantuml.jar";

	return render_uml(%params);
}

1
