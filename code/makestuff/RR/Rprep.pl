### Takes a bunch of filenames, usually generated by make
### Generates an R file that:
### ### loads all .RData files (and .RData files corresponding to .Rout files)
### ### makes .R files into a script (obeying START and END commands)
### ### Puts other file names an a variable called input_files
### ### saves image to a .RData file
### Make should pipe output to a .Rout file,
### and provide its name as first argument.
 
use strict;
use 5.10.0;
 
my $useCLArgs = "for (a in commandArgs(TRUE)){ eval(parse(text=a)) }";
 
my @env;
my @envir;
my @R;
my @input;
 
my $target = shift(@ARGV);
die "ERROR -- Rprep.pl: Illegal target $target (does not end with .Rout) \n" unless $target =~ s/.Rout$/.RData/;
die "ERROR -- Rprep.pl: No input files received, nothing to do.  A rule, script or dependency is probably missing from the project directory \n" unless @ARGV>0;
 
my $rtarget = $target;
$rtarget =~ s/\.RData//;
 
my $savetext = "save.image(file=\"$target\")";
my $save = $savetext;
 
foreach(@ARGV){
	s/Rout$/RData/;
	if ((/\.RData$/) or (/\.rda$/) or (/.R.env$/) or (/.Rdata/)){
		push @env, $_;
	} elsif (/\.R$/){
		push @R, $_;
	} elsif (/\.envir$/){
		s/.envir//;
		s/Rout$/RData/;
		push @envir, "\"$_\"";
	} else {
		push @input, "\"$_\"";
	}
}
 
foreach(@env){
	print "load('$_')\n";
}

if (@input){
	print "input_files <- c(";
	print join ", ", @input;
	print ")\n";
}

if (@envir){
	print "envir_list <- list(); ";
	print "for (f in  c(";
	print join ", ", @envir;
	say ")){envir_list[[f]] <- new.env(); load(f, envir=envir_list[[f]])}";
}

print "pdf(\"$rtarget.Rout.pdf\")\n# End RR preface\n";
 
if (@env){
	print "# Global Environment: ";
	print join " ", @env;
	print "\n\n";
}
 
if (@input){
	print "# Input: ";
	print join " ", @input;
	print "\n\n";
}
 
if (@R){
	print "# Scripts: ";
	print join " ", @R;
	print "\n\n";
}
 
if (@envir){
	print "# Environment list: ";
	print join " ", @envir;
	print "\n\n";
}
 
foreach my $f (@R){
	my $text;
	open (INF, $f);
	while(<INF>){
		if (/^END/){
			print STDERR ("END at line $. in $f\n");
			last;
		}

		next if (/No_R_pipe/);

		if (/setpdf/){
			s/^# *//;
			s/setpdf\s*\(\)/dev.off(); pdf("RTARGET.Rout.pdf")/;
			s/setpdf\s*\(/dev.off(); pdf("RTARGET.Rout.pdf", /;
		}

		if (/RTARGET/){
			s/^# *//;
			s/RTARGET/$rtarget/g;
		}
		if (/useCLArgs/){
			s/^# *//;
			s/useCLArgs/$useCLArgs/g;
		}
		$text .= $_;
		if (/^START/){
			print STDERR ("START at line $. in $f\n");
			$text = "";
			$save= $savetext;
		}

		if (/rdsave/){
			$save = $_;
			$save =~ s/^# *//;
			if ($save =~/^#/) {$save=$savetext} else{
				$save =~ s/rdsave\s*\(/save(file="$target", / or die("Problem with special statement $save");
			}
		}
 
		if (/rdnosave/){
			$save = "";
		}
	}
	print $text;
}
 
print "\n# Begin RR postscript\n# If you see this in an R log, your R script did not close properly\n$save\n";
