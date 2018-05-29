#!/share/apps/perl5/bin/perl
#===============================================================================
#
#         FILE: submit-jobs.sh.SGE.pl
#
#        USAGE: ./submit-jobs.sh.SGE.pl
#
#  DESCRIPTION:
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: ZHOU Yuanjie (ZHOU YJ), libranjie@gmail.com
# ORGANIZATION: R & D Department
#      VERSION: 1.0
#      CREATED: Mon Apr 24 19:51:24 2017 CST
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use utf8;
use Getopt::Std;

#===============================================================================
my $Version = "Tue Sep  5 14:41:43 CST 2017";
my $Contact = "ZHOU Yuanjie (ZHOU YJ), libranjie\@gmail.com";

#===============================================================================
our (
  $opt_i, $opt_b, $opt_n, $opt_m, $opt_c,
  $opt_p, $opt_q, $opt_r, $opt_w, $opt_h
);

#===============================================================================
&usage if ( 0 == @ARGV );
&usage unless ( getopts("i:b:n:m:c:p:q:rwh") );
&usage if ($opt_h);
&usage("-i must set before submit") unless ($opt_i);

#===============================================================================
my ($options);
$opt_b = 1      unless ( defined $opt_b );
$opt_n = 1      unless ( defined $opt_n );
$opt_m = "1G"   unless ( defined $opt_m );
$opt_c = 1      unless ( defined $opt_c );
$opt_p = "Jobs" unless ( defined $opt_p );
$opt_r = ( defined $opt_r ) ? 1 : 0;
$opt_w = ( defined $opt_w ) ? 1 : 0;
$options = "-cwd -V -l vf=$opt_m,p=$opt_c -N $opt_p ";
$options .= "-q $opt_q " if ( defined $opt_q );
&usage("-b must over than 1") if ( $opt_b < 1 );

#===============================================================================
my ( $block, %blocks, %jobwait, @info, $i, $subline, $j );

#===============================================================================
open IN, "<$opt_i" or die "read $opt_i $!\n";
&submkdir( $opt_i . ".split" );
&submkdir( $opt_i . ".submit" );
$i = 0;
while (<IN>) {
  $block = $opt_b - 1;
  $blocks{$i} = $_;
  while ($block) {
    $_ = <IN>;
    $blocks{$i} .= $_;
    --$block;
  }
  ++$i;
}
close IN;
$opt_n = ( $opt_n and $opt_n < $i ) ? $opt_n : $i;
$subline =
  ( $i / $opt_n > int( $i / $opt_n ) )
  ? int( $i / $opt_n ) + 1
  : int( $i / $opt_n );

#===============================================================================
@info = sort { $a <=> $b } keys %blocks;
for ( $i = 0 ; $i < @info ; ++$i ) {
  open OT, ">$opt_i.split/$i.sh" or die "write $opt_i.split/$i.sh $!\n";
  print OT "#!/bin/bash\n";
  print OT "date\n" unless ( $blocks{$i} =~ /^date/ );
  print OT "echo start $opt_i.split/$i.sh\n";
  print OT $blocks{$i};
  print OT "echo finish $opt_i.split/$i.sh\n";
  print OT "date\n";
  close OT;
}

#===============================================================================
for ( $i = 0 ; $i < @info ; $i += $subline ) {
  open SH, ">$opt_i.submit/$i.sh" or die "write $opt_i.submit/$i.sh $!\n";
  print SH "#!/bin/bash\n";
  for ( $j = 0 ; $j < $subline ; ++$j ) {
    last if ( $i + $j eq scalar @info );
    print SH "sh $opt_i.split/", $i + $j, ".sh\n";
  }
  close SH;
  chmod 0751, $opt_i . ".submit/$i.sh";
  &subJobExecute( $opt_i . ".submit/$i.sh", $options, $opt_r, \%jobwait );
}
&subJobsWait( \%jobwait ) if ( $opt_r && $opt_w );

#===============================================================================
sub subJobExecute {
  my ( $sh, $options, $qsub, $jobwait ) = @_;
  my ($msg);
  if ($qsub) {
    open SH, "qsub $options -e $sh.err -o $sh.log $sh |"
      or die "qsub $options -e $sh.err -o $sh.log $sh $!\n";
    chomp( $msg = <SH> );
    die $msg unless ( $msg =~ /Your job (\d+) .* has been submitted/ );
    close SH;
    $jobwait->{$1} = 1;
  }
  else {
    print "qsub $options -e $sh.err -o $sh.log $sh \n";
  }
}

#===============================================================================
sub subJobsWait {
  my ($jobwait) = @_;
  my ( $head, @info, $finish, $time );
  $finish = 1;
  $time   = 10;
  while ($finish) {
    open QS, "qstat |" or die "qstat $!\n";
    $head = <QS>;
    return unless ($head);
    <QS>;
    $finish = 0;
    while (<QS>) {
      chomp;
      @info = split;
      next unless ( defined $jobwait{ $info[0] } );
      ++$finish;
    }
    close QS;
    last unless ($finish);
    sleep($time);
    $time += 30;
    $time = ( $time > 300 ) ? 10 : $time;
  }
}

#===============================================================================
sub submkdir {
  my ($subdir) = @_;
  mkdir $subdir or die "mkdir $subdir $!\n" unless ( -d $subdir );
}

#===============================================================================
sub usage {
  my ($reason) = @_;
  print STDERR "
  ==============================================================================
  $reason
  ==============================================================================
  " if ( defined $reason );
  print STDERR "
  Last modify: $Version
  Contact: $Contact

  This is for submit jobs to the SGE clusters
  Usage:
  \$perl $0 -i [jobs.sh] [options]
  -i  --input     work.sh
  -b  --blocks    number of basic jobs array, default 1
  -n  --number    number for parallel job, 0 for every blocks, default 1
  -m  --ram       ram memory for the jobs, e.g. 1G, default 1G
  -c  --ncpus     number of cpu for each jobs, default 1
  -p  --prefix    prefix of submit jobs names, default Jobs
  -q  --queue     queue for submit, e.g. all.q default no
  -r  --run       submit jobs to SGE cluster, default print only
  -w  --wait      wait for submit jobs finished, default no
  -h  --help      help information
  ";
  exit;
}
