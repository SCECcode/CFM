#!/usr/bin/perl
# fixTS.pl
# Written 2016-10-12 by Scott T. Marshall 
# Updated 2020-07-03
#   Now automatically re-numbers vertices so they start at 1 and are sequential
#-----------------------------------------------------------------------------------------------------------------------------#
# 
# This script reads in a gocad t-surf file and does the following tasks
#   1) Removes multiple TFACE entries in a single surface, so every fault is a single patch. 
#      This happens when you group surfaces in 3DMove, or in many raw SCEC CFM files. 
#   2) The renumbers vertices, if needed, so that all VRTX are sequentially numbered. It also fixes the
#      corresponding TRGL lines with the properly ordered VRTX numbers.
#	3) The fixed ts file has two options 
#        1) Same filename but ends in _2.ts instead of .ts
#        2) Same filename but put in a different directory
# 
# After running this script, you should probably run remVRTX.pl to remove all of the duplicate vertices that 
# lie along the borders of the TFACE surface patches (i.e. where grouped surfaces used to touch).
# 
#   Usage: fixTS.pl file.ts
# 
#-----------------------------------------------------------------------------------------------------------------------------#

#-----------------------------------------------------------------------------------------------------------------------------#
#------- USER CONFIGURABLE PARAMETERS ----------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------------#
#What filename option should I use
#  1=same filename but add _2.ts instead of .ts
#  2=same filename but in a different directory
$fileOpt=2;
#Do not include the trailing slash. This is on used if $fileOpt=2. 
$dir="fixed";



#-----------------------------------------------------------------------------------------------------------------------------#
#------- BASIC ERROR HANDLING ------------------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------------#
#chech for correct usage
if (@ARGV!=1){
	#print the script usage
	print "\n   Usage: fixTS.pl file.ts\n\n";
	exit;
}#end if

#Get the filename from the command line
$file=$ARGV[0];

#check to make sure file exists
unless(-e $file){
	print "\nError: $file not found\n\n";
	exit;
}#end if

#make the new filename 
$newFile=$file;
if   ($fileOpt==1){$newFile=~s/\.ts/_2\.ts/}
elsif($fileOpt==2){$newFile="$dir/$newFile"}

#print "$newFile\n";
#exit;



#-----------------------------------------------------------------------------------------------------------------------------#
#------- READ AND FIX THE GOCAD FILE -----------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------------#
print "Reading: $file\n";
print "---------------------------------------------------------------------\n";

open(TS,$file);
open(NEW,">$newFile");

#make vrtx, trgl, and other counters
$countVRTX=0;
$countTRGL=0;
$countTFACE=0;
#make counters for the entire file
$countSURF=0;
$countAllVRTX=0;
$countAllTRGL=0;
#make a flag to let the user know if vertices were re-ordered
$flag="No";


#read through the ts file line by line
while(<TS>){
	chomp;
	@data=split(" ",$_);
	
	#look for lines with the surface name
	if($data[0] =~ "name:"){
		#increment the surface counter
		$countSURF++;
		
		#grab the surface name
		$name=$data[0];
		$name=~s/name://;
		print "$countSURF) $name\n";
		
		#print the line to the new TS file as is
		print NEW "$_\n";
	}#end if
	
	#look for TFACE lines
	elsif($data[0] eq "TFACE"){
		#increment the tface counter
		$countTFACE++;
		if($countTFACE==1){
			print NEW "$_\n";
		}#end if
	}#end elsif
	
	#look for VRTX lines
	elsif($data[0] eq "VRTX"){
		#increment the vrtx counters
		$countVRTX++; $countAllVRTX++;
		
		#check to make sure vrtx are in order
		if($data[1]!=$countVRTX){
			#set the flag to one to indicate that reordering was done
			$flag="Yes";
			#print a message about which VRTX's were renumbered
			#print "VRTX $data[1] --> VRTX $countVRTX\n";
		}#end if
		
		#store the actual vertex number in an array that is sequentially ordered
		$v[$data[1]]=$countVRTX;
		
		#print the vertex line with the vertices sequentially ordered
		print NEW "VRTX $countVRTX  $data[2]  $data[3] $data[4]\n";
		
	}#end elsif
	
	#look for TRGL lines
	elsif($data[0] eq "TRGL"){
		#increment the trgl counters
		$countTRGL++; $countAllTRGL++;
		
		#don't print the trgls yet; just store them.
		#push(@trgl,$_);
		
		#print the elt line, but reference the v array which has the correct order of vertices
		print NEW "TRGL $v[$data[1]] $v[$data[2]] $v[$data[3]]\n";
			
	}#end elsif
	
	#look for the END keyword
	elsif($data[0] eq "END"){
		#print the END keyword
		print NEW "END\n";
		
		#print some useful stats for each surface
		print "     Num VRTX  : $countVRTX\n";
		print "     Num TRGL  : $countTRGL\n";
		print "     Num TFACE : $countTFACE\n";
		print "     Reordered : $flag\n";
		
		#now clear out the trgl array and counters for the next fault
		@trgl=();
		$countVRTX=0; $countTRGL=0; $countTFACE=0;
		$flag="No";
		
	}#end elsif
	
	#if none of these, print the line as is
	else{print NEW "$_\n"}
	
}#end while


#print some final stats to stdout
print "---------------------------------------------------------------------\n";
print "Total Objects: $countSURF\n";
print "  Total VRTX: $countAllVRTX\n";
print "  Total TRGL: $countAllTRGL\n\n";



