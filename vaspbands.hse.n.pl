#!/usr/bin/perl
#fork from vaspbands.pl of ccao
#used for n kpoints per path
#
# Usage: 
#           vaspbands.hse.n.pl \${Kpoints_Per_Path} \${trivialhead} > bands.dat
#
# ${trivalhead} is number of kpt should be ignored at the head of EIGENVAL file,
# it is used for hse|mbj band calcualtion, ignore the k-points mesh not for bnd.
#

use Scalar::Util qw(looks_like_number);

$num_args = $#ARGV + 1;

if ( $num_args > 0 ) {
    for($i=0;$i<$num_args;$i++){
        if ( ! looks_like_number($ARGV[$i])){
            printf(STDERR "Usage: vaspbands.hse.n.pl \${Kpoints_Per_Path} \${trivialhead} > bands.dat\n");
            exit;
        }
    }
}

if ($num_args < 2) {
    $trivalhead=0;
}
else{
    $trivalhead=$ARGV[1];        #how many trival kpts at beginning  which has nothing to do with bnds
}

if ($num_args < 1) {
    $Kpoints_Per_Path=100;
}
else{
    $Kpoints_Per_Path=$ARGV[0];
}

printf(STDERR "Kpoints_Per_Path =%6d\ntrivalhead       =%6d\n", $Kpoints_Per_Path, $trivalhead);

use Carp;
open(FILE, "EIGENVAL");

$_=<FILE>;		#read a line
@tmp=split;
$nspin=$tmp[3];
for($i=0;$i<4;$i++) {	#skip 4 lines
  $_=<FILE>;
}

$_=<FILE>;		#read the 6th line
@tmp=split;
$nkpts=$tmp[1]-$trivalhead;     #number of k-points
$nbnds=$tmp[2];		#nubmer of bands

$LinesToSkip=$trivalhead*($nbnds+2);
for($i=0;$i<$LinesToSkip;$i++) {    #skip lines of trival kpts
    $_=<FILE>;
}

for($i=0;$i<$nkpts;$i++) {
  $_=<FILE>;		#skip the line contains nothing
  $_=<FILE>;		#skip the line of the coordinate of the k-point
  for($j=0;$j<$nbnds;$j++) {
    $_=<FILE>;		#read the bands one by one
    @tmp=split;
    if($nspin==1) {
      $te[$j]=$tmp[1];
    }
    else {
      $te[$j*2]=$tmp[1];
      $te[$j*2+1]=$tmp[2];
    }
  }
  push @ebnds, [ @te ];
}

close(FILE);

open(FILE, "OUTCAR");

while($_=<FILE>) {
  if(/k-points in units of 2pi\/SCALE/) {
    $LinesToSkip=$trivalhead;
    for($i=0;$i<$LinesToSkip;$i++) {        #skip lines of trival kpts
        $_=<FILE>;
    }
    $_=<FILE>;
    @kold=split;
    $kpt[0]=0;
    for($i=1;$i<$nkpts;$i++) {
      $_=<FILE>;
      @knew=split;
      if($i%$Kpoints_Per_Path==0) {
         $kpt[$i]=$kpt[$i-1];
      }
      else{
         $kpt[$i]=$kpt[$i-1]+sqrt(($knew[0]-$kold[0])**2+($knew[1]-$kold[1])**2+($knew[2]-$kold[2])**2);
      }
      @kold=@knew;
    }
  }
}

for($i=0;$i<$nbnds;$i++) {
  for($j=0;$j<$nkpts;$j++) {
    if($nspin==1) {
      printf("%12.9f  %12.9f\n",$kpt[$j],$ebnds[$j][$i]);
    }
    else {
      printf("%12.9f  %12.9f  %12.9f\n",$kpt[$j],$ebnds[$j][$i*2],$ebnds[$j][$i*2+1]);
    }
    if(($j+1)%$Kpoints_Per_Path==0){
       if($i==0){
	       $xn=($j+1)/$Kpoints_Per_Path;
           printf(STDERR "x%d = %10.7f\n", $xn, $kpt[$j]);
       }
      printf("\n");
    }
  }
  printf("\n");
}
