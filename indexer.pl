#!/usr/bin/perl

# KSearch v1.4
# Copyright (C) 2000 David Kim (kscripts.com)
#
# Parts of this script are Copyright
# www.perlfect.com (C)2000 G.Zervas. All rights reserved
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA

my $t0 = time();
use Fcntl;
use locale;

###### You may have to add the full path to your configuration file below######
###############################################################################
my $configuration_file = 'configuration/configuration.pl'; #CONFIGURATION PATH#

require $configuration_file;

my $dbm_package;
if ($USE_DBM) {
	package AnyDBM_File;
	@ISA = qw(DB_File GDBM_File SDBM_File ODBM_File NDBM_File) unless @ISA;
	my $dbminfo;
	for (@ISA) {
  		if (eval "require $_") {
			$dbminfo .= "\n\nUsing DBM Database: $_...\n\n";
  			if ($_ =~ /[SON]DBM_File/) {
				# $USE_DMB = 0;
  				$dbminfo .= "Warning: $_ has block size limits.\n";
				$dbminfo .= "If your site exeeds the limit you will receive error message:\n";
				$dbminfo .= "[ dbm store returned -1, errno 28, key \"trap\" at - line 3. ]\n";
				$dbminfo .= "It is highly recommended to use a flat file database by setting \$USE_DBM to 0 in configuration.pl.\n";
				$dmbinfo .= "See the README file for details.\n\n";
  			}
			print $dbminfo;
			if ($_ =~ /[SON]DBM_File/) {
				print "\nINDEXING WILL CONTINUE IN 15 SECONDS\n";
				sleep 15;
			}
			$dbm_package = $_;
			last;
  		}
	}
	package main;
}

cleanup(); # delete existing db files

if ($MAKE_LOG) {
	my $indexmetadesc = $META_DESCRIPTION ? "yes" : "no";
	my $indexmetakeywords = $META_KEYWORD ? "yes" : "no";
	my $indexmetaauthor = $META_AUTHOR ? "yes" : "no";
	my $indexalttext = $ALT_TEXT ? "yes" : "no";
	my $indexlinks = $LINKS ? "yes" : "no";
	my $indexpdf = $PDF_TO_TEXT ? "yes" : "no";
	my $removecommonterms = $IGNORE_COMMON_TERMS ? "yes [cutoff = $IGNORE_COMMON_TERMS percent]" : "no";
	my $indexcontent = $SAVE_CONTENT ? "yes" : "no (warning: search may be very slow for large sites)";
	open(LOG,">".$LOG_FILE) or (warn "Cannot open log file $LOG_FILE: $!");
	print LOG localtime()."\nConfiguration File: $KSEARCH_DIR$configuration_file\n";
	print LOG $dbminfo;
	print LOG "\nINDEXER SETTINGS:\n";
	print LOG "Minimum term length: $MIN_TERM_LENGTH\n";
	print LOG "Description length: $DESCRIPTION_LENGTH\n";
	print LOG "Index meta descriptions: $indexmetadesc\n";
	print LOG "Index meta keywords: $indexmetakeywords\n";
	print LOG "Index meta authors: $indexmetaauthor\n";
	print LOG "Index alternative text: $indexalttext\n";
	print LOG "Index links: $indexlinks\n";
	print LOG "Index PDF files: $indexpdf\n";
	print LOG "Save file contents to database: $indexcontent\n";
	print LOG "Add Common terms to STOP TERMS file: $removecommonterms\n";
	print LOG "Index files with extensions: ".(join " ", @FILE_EXTENSIONS)."\n";
}

my ($allterms, $filesizetotal, $file_count);
my @ignore_files;
my %terms; 			#key = terms; value = number of files the term is found in;

my %f_file_db;			#file path
my %f_date_db;			#file modification date
my %f_size_db;			#file size
my %f_termcount_db;		#number of non-space characters in each file
my %descriptions_db; 		#file description
my %titles_db; 			#file title
my %filenames_db;		#file name
my %contents_db;		#file contents

my %alt_text_db;		#alt text
my %meta_description_db;	#meta descriptions
my %meta_keywords_db;		#meta keywords
my %meta_author_db;		#meta authors
my %links_db;			#links

if ($USE_DBM) {
	tie %f_file_db, $dbm_package, $F_FILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $F_FILE_DB_FILE: $!";
	tie %f_date_db, $dbm_package, $F_DATE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $F_DATE_DB_FILE: $!";
	tie %f_size_db, $dbm_package, $F_SIZE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $F_SIZE_DB_FILE: $!";
	tie %f_termcount_db, $dbm_package, $F_TERMCOUNT_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $F_TERMCOUNT_DB_FILE: $!";
	tie %descriptions_db, $dbm_package, $DESCRIPTIONS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $DESCRIPTIONS_DB_FILE: $!";
	tie %titles_db, $dbm_package, $TITLES_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $TITLES_DB_FILE: $!";
	tie %filenames_db, $dbm_package, $FILENAMES_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $FILENAMES_DB_FILE: $!";
	if ($SAVE_CONTENT) {
		tie %contents_db, $dbm_package, $CONTENTS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $CONTENTS_DB_FILE: $!";
	}
	if ($ALT_TEXT) {
		tie %alt_text_db, $dbm_package, $ALT_TEXT_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $ALT_TEXT_DB_FILE: $!";
	}
	if ($META_DESCRIPTION) {
		tie %meta_description_db, $dbm_package, $META_DESCRIPTION_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $META_DESCRIPTION_DB_FILE: $!";
	}
	if ($META_KEYWORD) {
		tie %meta_keyword_db, $dbm_package, $META_KEYWORD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $META_KEYWORD_DB_FILE: $!";
	}
	if ($META_AUTHOR) {
		tie %meta_author_db, $dbm_package, $META_AUTHOR_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $META_AUTHOR_DB_FILE: $!";
	}
	if ($LINKS) {
		tie %links_db, $dbm_package, $LINKS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $LINKS_DB_FILE: $!";
	}
}

push @FILE_EXTENSIONS, 'pdf' if $PDF_TO_TEXT; # if the option to index PDF files is chosen

print "\nLoading files to ignore:\n";
print LOG "\nLoading files to ignore:\n" if $MAKE_LOG;

ignore_files();

print "\n\nUsing stop words file: $IGNORE_TERMS_FILE\n";
print LOG "\n\nUsing stop words file: $IGNORE_TERMS_FILE\n" if $MAKE_LOG;

my $stopwords_regex = ignore_terms();

print "\nStarting indexer at $INDEXER_START\n\n";
print LOG "\nStarting indexer at $INDEXER_START\n\n" if $MAKE_LOG;

if (!$USE_DBM) {
	open(FILEDB, ">$DATABASEFILE") || die "Cannot open database file: $!\n";
}

indexer($INDEXER_START);

close(FILEDB) if (!$USE_DBM);

# remove COMMON TERMS previously appended to STOP TERMS file
clean_stop_terms();

# append COMMON TERMS to STOP TERMS file if configured to do so
append_common_terms() if $IGNORE_COMMON_TERMS;

print "\n\nFinished: Indexed ".$file_count.' files ('.$filesizetotal.'KB) with '.$allterms." total terms.\n";
print LOG "\n\nFinished: Indexed ".$file_count.' files ('.$filesizetotal.'KB) with '.$allterms." total terms.\n" if $MAKE_LOG;

print "Saved information ".$logterms."in logfile:\n $LOG_FILE\n\n" if $MAKE_LOG;

my $timediff = time() - $t0;
my $seconds = $timediff % 60;
my $minutes = ($timediff - $seconds) / 60;
if ($minutes >= 1) { $minutes = ($minutes == 1 ? "$minutes minute" : "$minutes minutes"); } else { $minutes = ""; }
$seconds = ($seconds == 1 ? "$seconds second" : "$seconds seconds");
print "Total run time: $minutes $seconds\n";
print LOG "Total run time: $minutes $seconds\n" if $MAKE_LOG;
close (LOG) if $MAKE_LOG;


####sub routines###########################################################################

sub indexer {
  my $dir = $_[0];
  my ($file_ref, $file);
  chdir $dir or (warn "Cannot chdir $dir: $!\n");
  opendir(DIR, $dir) or (warn "Cannot open $dir: $!\n");
  my @dir_contents = readdir DIR;
  closedir(DIR);
  my @dirs  = grep {-d and not /^\.{1,2}$/} @dir_contents;
  my @files = grep {-f and /^.+\.(.+)$/ and grep {/^\Q$1\E$/} @FILE_EXTENSIONS} @dir_contents;
  FILE: foreach my $file_name (@files) {
    $file = $dir."/".$file_name;
    $file =~ s/\/\//\//og;
    foreach my $skip (@ignore_files) {
      next FILE if $file =~ m/^$skip$/;
    }
    index_file($file);
  }
  DIR: foreach my $dir_name (@dirs) {
    $file = $dir."/".$dir_name;
    $file =~ s/\/\//\//og;
    foreach my $skip (@ignore_files) {
      next DIR if $file =~ /^$skip$/;
    }
    indexer($file);
  }
}

sub index_file {
  my $file = $_[0];
  my ($contents, $f_termcount);
  my %totalterms;
  my %term_total;
  if($PDF_TO_TEXT && $file =~ m/\.pdf$/i) {	# if the file is a PDF file
    if( $file !~ m/^[\/\\\w.+-]*$/ || $file =~ m/\.\./ ) {
      print "\nIgnoring PDF file '$file': filename has illegal characters\n\n";
      print LOG "\nIgnoring PDF file '$file': filename has illegal characters\n\n" if $MAKE_LOG;
      return;
    }
    $contents = `$PDF_TO_TEXT "$file" -` or (print "\nCannot execute '$PDF_TO_TEXT $file -'\nIgnoring PDF file '$file'\n\n");
    unless ($contents) {
	    print LOG "\nCannot execute '$PDF_TO_TEXT $file -'\nIgnoring PDF file '$file'\n\n" if $MAKE_LOG;
    }
  } else {
    undef $/;
    open(FILE, $file) or (warn "Cannot open $file: $!");
    $contents = <FILE>;
    close(FILE);
    $/ = "\n";
  }

  if ($contents =~ /^\s*$/gs) { return; } # skip empty files

  ++$file_count; # file reference number
  $f_size_db{$file_count} = int((((stat($file))[7])/1024)+.5);	# get size of file in kb
  $filesizetotal += $f_size_db{$file_count};			# get total size of all files
  my $update = (stat($file))[9];	 			# get date of last file modification
  $f_date_db{$file_count} = int($update/8640);
  $update = get_date($update);

  print "Indexed $file \n Last Updated: $update \n File Size: $f_size_db{$file_count} KB\n";
  print LOG "Indexed $file \n Last Updated: $update \n File Size: $f_size_db{$file_count} KB\n" if $MAKE_LOG;

  $file =~ m/^$INDEXER_START(.*)$/;
  $file = $1;
  $f_file_db{$file_count} = $file;

  if ($file =~ /[\/\\]([^\/\\]+)$/) {
	  $filenames_db{$file_count} = $1;
  } else {
	  $filenames_db{$file_count} = $file;
  }

  # save content if configured to do so, remove html and scripts
  $contents = process_contents($contents, $file_count, $file);

   while ($contents =~ m/\b(\S+)\b/gs) {
    my $term = $1;
    $f_termcount_db{$file_count} += length $term;			# count all non-space characters in file
    $f_termcount++;
    if ($IGNORE_COMMON_TERMS) {						# count terms in file
	    next if $term =~ m/^$stopwords_regex$/io;			# skip stop words
	    if (length $term >= $MIN_TERM_LENGTH && !$term_total{$term}) {	# each term in file if valid
	      $term_total{$term} = undef;
	    }
    }
  }
  $allterms += $f_termcount;					# count all terms in all files
  if ($IGNORE_COMMON_TERMS) {
	  foreach (keys %term_total) {
	    $terms{$_}++;					# count files with each term
	  }
  }


##########################################################################################

 if (!$USE_DBM) {
 	# Save all hash data into flat files with | delimiter

	my $file_entry = $f_file_db{$file_count};			# file path
	my $filename_entry = $filenames_db{$file_count};		# file name
	my $date_entry = $f_date_db{$file_count};			#file modification date
	my $size_entry = $f_size_db{$file_count};			#file size
	my $termcount_entry = $f_termcount_db{$file_count};		#number of non-space characters in each file
	my $descriptions_entry = $descriptions_db{$file_count}; 	#file description
	my $titles_entry = $titles_db{$file_count}; 			#file title
	my $contents_entry = $contents_db{$file_count};			#file contents
	my $alt_text_entry = $alt_text_db{$file_count};			#alt text
	my $meta_desc_entry = $meta_description_db{$file_count};	#meta descriptions
	my $meta_key_entry = $meta_keywords_db{$file_count};		#meta keywords
	my $meta_auth_entry = $meta_author_db{$file_count};		#meta authors
	my $links_entry = $links_db{$file_count};			#links

	print FILEDB "$file_entry\t$filename_entry\t$date_entry\t$size_entry\t$termcount_entry\t$descriptions_entry\t$titles_entry\t$contents_entry\t$alt_text_entry\t$meta_desc_entry\t$meta_key_entry\t$meta_auth_entry\t$links_entry\n";

}

##########################################################################################

}

sub get_date {  # gets date of last modification
   my $updatetime = $_[0];
   my @month = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
   my ($mday,$mon,$yr) = (localtime($updatetime))[3,4,5];
   $yr += 1900;
   my $date = "$month[$mon] $mday, $yr";
   $date ||= "n/a";
   return $date;
}

sub process_contents {  # process contents
  my ($contents, $file_ref, $filename) = @_;
  if ($ALT_TEXT) {
	my $alt_text;
	while ($contents =~ m/\s+alt\s*=\s*[\"\'](.*?)[\"\'][> ]/gis) {
	        $alt_text .= "$1 ";
	}
	$alt_text =~ s/\s+/ /g;
	$alt_text_db{$file_ref} = $alt_text if $alt_text;
  }
  if ($LINKS) {
	my $links;
	while ($contents =~ m/<\s*a\s+href\s*=\s*[\"\'](.*?)[\"\'][> ]/gis) {
	        $links .= "$1 ";
	}
	$links =~ s/\s+/ /g;
	$links_db{$file_ref} = $links if $links;
  }
  if ($META_DESCRIPTION) {
  	if ($contents =~ m/<\s*META\s+name\s*=\s*[\"\']?description[\"\']?\s+content\s*=\s*[\"\']?(.*?)[\"\']?\s*>/is) {
		my $meta_descript = $1;
		$meta_descript =~ s/\s+/ /g;
		$meta_description_db{$file_ref} = $meta_descript;
	}
  }
  if ($META_KEYWORD) {
  	if ($contents =~ m/<\s*META\s+name\s*=\s*[\"\']?keywords[\"\']?\s+content\s*=\s*[\"\']?(.*?)[\"\']?\s*>/is) {
		my $meta_key = $1;
		$meta_key =~ s/\s+/ /g;
		$meta_keyword_db{$file_ref} = $meta_key;
	}
  }
  if ($META_AUTHOR) {
  	if ($contents =~ m/<\s*META\s+name\s*=\s*[\"\']?author[\"\']?\s+content\s*=\s*[\"\']?(.*?)[\"\']?\s*>/is) {
		my $meta_aut = $1;
		$meta_aut =~ s/\s+/ /g;
		$meta_author_db{$file_ref} = $meta_aut;
	}
  }
  $contents =~ s/(<\s*script[^>]*>.*?<\s*\/script\s*>)|(<\s*style[^>]*>.*?<\s*\/style\s*>)/ /gsi;	# remove scripts and styles

  record_description($file_ref, $filename, $contents);	# record titles and descriptions

  $contents =~ s/<\s*TITLE\s*>\s*(.*?)\s*<\s*\/TITLE\s*>//gsi;	# remove title
  $contents =~ s/<digit>|<code>|<\/code>//gsi;
  $contents =~ s/(<[^>]*>)|(&nbsp;)|(&#160;)/ /gs;		# remove html poorly
  $contents = translate_characters($contents);			# translate ISO Latin special characters to English approximations
  $contents =~ s/^\s+//gs;