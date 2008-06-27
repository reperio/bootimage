#!/usr/bin/perl

my $PATH = $ARGV[0];

if (!$PATH) {

	die "You must specify a path!";
}

my %libs;

@exefiles = `find $PATH -type f -perm /u+x -print`;

for my $i (@exefiles) {

	open(LDD, "ldd $i |") || die "$!";
	while (my $line = <LDD>) {
		chomp $line;
		if ($line =~ /\=\>/) {
			$line =~ s/\([^\)]+\)//g;
			my ($short, $libpath) = split(/ \=\> /, $line);

			if ($libpath =~ /^\//) {
				$libs{$libpath} = 1;
			}
		}
	}
	close(LDD);

	#print $ldd . "\n\n";

}

foreach my $library (sort keys %libs) {
	system("cp $library $PATH/$library");
	print $library . "\n";
}
