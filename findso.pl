#!/usr/bin/perl

my $PATH = $ARGV[0];

if (!$PATH) {

	die "You must specify a path!";
}

my %libs;

while ($i = <$PATH/usr/local/bin/*>) {

	#print "Finding shared objects for $i\n";
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
