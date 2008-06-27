#!/usr/bin/perl

my $PATH = $ARGV[0];

if (!$PATH) {

	die "You must specify a path!";
}

my %libs;

@exefiles = `find $PATH -type f -perm /u+x -print`;

for my $i (@exefiles) {

	#print "Looking at $i\n";

	open(LDD, "ldd $i |") || die "$!";
	while (my $line = <LDD>) {
		chomp $line;
		if ( ($line =~ /\=\>/) || ($line =~/^\s+\//)) {
			$line =~ s/\([^\)]+\)//g;
			my ($short, $libpath) = split(/ \=\> /, $line);

			$short =~ s/^\s+//g;
			$short =~ s/\s+$//g;

			$libpath =~ s/^\s+//g;
			$libpath =~ s/\s+$//g;

			if ($short =~ /^\s*\//) {
				#print "SHORT = $short\n";
				$libs{$short} = 1;
			}
			elsif ($libpath =~ /^\//) {
				$libs{$libpath} = 1;
			}
		}
	}
	close(LDD);

	#print $ldd . "\n\n";

}

foreach my $library (sort keys %libs) {
	system("cp --parents $library $PATH");
	print $library . "\n";
}
