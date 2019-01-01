#!/usr/bin/perl

# Turns a bit of text into a single image suitable for display.

require 5;
use diagnostics;
use strict;
use bytes;
use POSIX;
use Fcntl;
use Image::Magick;
use Getopt::Std;
use List::Util qw(max min);
use Data::UUID;
use File::Spec;

my $maxEverPointsize = 0;
my $cline = "$0 @ARGV";
$cline =~ s/\\/\\\\\\/g;
getopts("w:h:f:p:d:t:m:");
our ($opt_w, $opt_h, $opt_f, $opt_p, $opt_d, $opt_t, $opt_m);

my $filetype = $opt_t || "gif";  # File type of resulting image
my $canvasWidth = $opt_w || 800; # Width of output image in pixels
my $canvasHeight = $opt_h || 480; # Height of output image in pixels
my $margin = 18;
my $quoteCount = 0;
my $font = $opt_f || "C:\\windows\\fonts\\ARBERKLEY.ttf"; # Font name
my $prefix = $opt_p || "a";      # Prefix to add to output file name
my $dir = $opt_d || ".";         # Directory for output file
my $mpointsize = $opt_m || 60;   # Maximum point size

# List of background colors, one will be chosen at random
my @colors = ("green","olive","purple","indigo","brown");

# Read the input text from either a specified file or stdin
my $quotetext = do { local( $/ ) = $ARGV[1]; <> };

# Separate the lines
my @quote = split(/\n/, $quotetext);

# If there was no text, exit
$quotetext || exit(1);

# Get a UUID for a unique output file name
my $ug = Data::UUID->new;

# Construct the path for our output file
my $outpath = File::Spec->catfile( ($dir), 
				   $prefix . 
				   "-" . 
				   $ug->create_str() . 
				   "." . 
				   $filetype );
# Create our output
renderQuote(\@quote, $outpath, 
	    $font,
	    $colors[int(rand($#colors+1))]);

sub renderQuote 
{
    my ($quote, $filename, $font, $bgcolor) = @_;

    # Text color will be white, unless the background is as well
    my $fgcolor = ($bgcolor eq "white" ? "black" : "white");

    # Create image object
    my $image = Image::Magick->new(size=>"${canvasWidth}x${canvasHeight}");

    # Create a blank canvas with our desired background
    $image->ReadImage("xc:${bgcolor}");

    # Determine what point size will fit
    my $pointsize = getQuotePointSize($image,
				      $quote, $canvasWidth, $margin, $font);
    
    $maxEverPointsize = max($pointsize, $maxEverPointsize);

    # Get the size of our output text image
    my ($quoteWidth, $quoteHeight) =
	getQuoteWidthHeight($image, $quote, $pointsize,$font);


    # Based on the sie of our output text image, determine the position on
    # the canvas to start writing.
    my $x = ($canvasWidth - $quoteWidth)/2;
    my $y = ($canvasHeight - ($quoteHeight * 0.85))/2;
    
    my $line;

    # Write out each line in the text
    foreach $line (@{ $quote }) {

	$image->Annotate(
	    font=>$font,
	    pointsize=>$pointsize,
	    fill=>'white',
	    text=>$line,
	    'x'=>$x,
	    'y'=>$y,
	    fill=>$fgcolor);

	# Adjust our positon for the next line based on the height of the
	# line we just created
	my ($lineWidth, $lineHeight) = 
	    ($image->QueryFontMetrics(font=>$font,
				      pointsize=>$pointsize,text=>$line))[4,5];

	$y+=$lineHeight;

    }

    # Write the image to the file and exit
    my $status = $image->Write('filename'=>$filename);
    return($status);

}

# Get the total width and height of the quote
sub getQuoteWidthHeight
{
   my ($image, $quote, $pointsize, $font) = @_;
   my $line;
   my $height = 0;
   my $width = 0;
   my ($textWidth, $textHeight);
    foreach $line (@$quote) {
	($textWidth, $textHeight) = 
	    ($image->QueryFontMetrics(font=>$font,
				      pointsize=>$pointsize,text=>$line))[4,5];
	$width = max($width, $textWidth);
	$height += $textHeight;

    }
   return($width, $height);

}

# Get the largest point size that can render the full quote
sub getQuotePointSize
{
    my ($image, $quote, $canvisWidth, $margin, $font) = @_;
    my $line;
    my @sizes = ();
    my $lines = scalar @$quote;

    foreach $line (@$quote) {
 	push(@sizes, getMaxPointSize($image, $line,
				     $canvasWidth, $margin, $font,$lines));
    }
    return(min(@sizes));
}

# Get the largest point size that can render the line
sub getMaxPointSize
{
    my ($image, $text, $canvasWidth, $margin, $font, $lines) = @_;
    my $textWidth;
    my $textHeight;
    my $pointsize = $mpointsize;
    
    do {
	$pointsize--;
	($textWidth, $textHeight) = 
	    ($image->QueryFontMetrics(font=>$font,
				      pointsize=>$pointsize,text=>$text))[4,5];
    } while (($textWidth + ($margin * 2) > $canvasWidth) ||
            (($textHeight * $lines) > ($canvasHeight * 0.85)))
	     ;

    return($pointsize);
}
