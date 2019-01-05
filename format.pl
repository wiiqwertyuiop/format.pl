use strict;
use warnings;
use Tie::File;

print "Filename:\n";
chomp(our $file = <>);

##tie my @array, 'Tie::File', $file or die;
tie my @file, 'Tie::File', $file or die;
our @array = @file;
untie(@file);

our @out;

my $i = 0;
foreach(@array) {
  $array[$i] =~ s/A:....\sX:....+$//g;  # get rid of snes9x junk
  $array[$i] =~ s/\*\*\* NMI//g;    # get rid of NMI
  $array[$i] =~ s/\[\$..:..+?\]//g;    # get rid of read/jump location (except for the branching inscructions)
  
  $array[$i] =~ s/^\$(..)\/(.+?)\s(.+?\s\s*)(.+)$/CODE_$1$2:    $3$4/g;     # format
  
  $array[$i] =~ s/...\s\s+?\[(.+?)\]/$1/g;        #fix boxes for branches and JSR and stuff
  #$array[$i] =~ s/\[\$..:....\]//g;
  
  $array[$i] =~ s/CODE_(..)(.+?):(\s\s+?.+?\s\s+)(.+?\s)\$([8-9A-F][0-9A-F][0-9A-F][0-9A-F])\s*$/CODE_$1$2:$3$4CODE_$1$5/g;    # JSR and stuff
  
  $array[$i] =~ s/(...)\s\$([8-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F])/$1 CODE_$2/g;   # JSL and stuff
  
  $i++;
}

##print @array;
##untie(@array);
##system("pause");

$file =~ s/\..+$//;
open (MYFILE, '>', "$file.asm"); 

@out = sort { 
  if($a =~ /^$/) { return 1; }
  elsif($b =~ /^$/) { return -1; }
  else { return $a cmp $b; }
} @array;  # sort

$i = 0;
foreach my $temp (@out) {
  
  print MYFILE "$temp";
    
  if($temp !~ /^$/) {   # don't add a line break if a empty line
    
    if($temp !~ /\r\n/ && defined $out[$i+1]) {
      my $temp2 = $temp;
      $temp2 =~ s/CODE_.+?\s\s+(.+?)\s+\s*[A-Z][A-Z][A-Z].+/$1/;    # get number of bytes the opcode takes up
      my $size =()= $temp2 =~ /[0-9A-F-a-f][0-9A-F-a-f]/g; 
          
      my $temp3 = $temp;
      $temp3 =~ s/^CODE_(.+?):.+/$1/;     # get current addr
      $temp3 = hex($temp3);
      
      my $temp4 = $out[$i+1];           # get next addr
      $temp4 =~ s/^CODE_(.+?):.+/$1/;
      $temp4 = hex($temp4);
      
      if($temp =~ /JMP/ || $temp =~ /BRA/ || $temp =~ /JML/ || $temp =~ /BRL/ || $temp =~ /RTS/ || $temp =~ /RTL/) {
        # adda line break after these opcodes
        print MYFILE "\n";
      } elsif(($temp3+$size) != $temp4) {
        # add two line breaks if the next address doesn't come after this one
        print MYFILE "\n\n";
      }
    }
    # add a line break
    print MYFILE "\n";
  }
  
  $i++;
}

#untie(@array);
close (MYFILE); 

print "Done!\n";