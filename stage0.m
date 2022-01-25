### MIT License
### 
### Copyright (c) 2021-2022 Patryk Maciej Król
### 
### Permission is hereby granted, free of charge, to any person obtaining a copy
### of this software and associated documentation files (the "Software"), to deal
### in the Software without restriction, including without limitation the rights
### to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
### copies of the Software, and to permit persons to whom the Software is
### furnished to do so, subject to the following conditions:
### 
### The above copyright notice and this permission notice shall be included in all
### copies or substantial portions of the Software.
### 
### THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
### IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
### FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
### AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
### LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
### OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
### SOFTWARE.

### This is cutter only.

### changelog: x, y coordinates cleanup in all stages

INFO = "This is only cutter script. Check if generated images contains whole speciment.\n\nIf Your samples differs, change sample_coords. \nhint: use gimp to find coords and size or calculate it\n\n";

#config 
input_directory = 'source/';
output_directory = 'output-s0/';
dpi = 4800;
holeRadAdd = 50;
asciiSkip = 0;  #9
skipMM = 16;  #16, 14, -1, -3

#no longer applicable, calculated automatically. See line 93.
##firstPeak = 30;
##secondPeak = 110;

asciiNumTable = [65+asciiSkip:90 97:122];

# samples coords and sizes, coords from upper left
# for samples coords (upper left) generator
sampleSize = [4095 4095];
sampleXs = [420 5450 10500];   ;#cols

sampleYs = [      
 #2 plates, good scan      
     220      #ABC
    4500      #DEF
    8850      #GHI
   13270      #JKL (+150)
   17650      #MNO
   21980      #PQR
                 ];        #rows

##sampleYs = [      
## #1 plate, good scan      
##     220      #ABC
##    4500      #DEF
##    8850      #GHI
##                 ];        #rows

##sampleYs = [     
##    #3 plates, good scan
####     220      #ABC
####    4500      #DEF
####    8850      #GHI
##   13220      #JKL
##   17650      #MNO
##   21980      #PQR
##                 26410      #STU
##                 30780      #WVX
##                 35180];    #YZa        #rows


##sampleYs = [     
##    #local mod
####     220      #ABC
####    4500      #DEF
####    8850      #GHI
##   13520      #JKL +300   +3mm    #ABC
##   17650      #MNO                #DEF
##   21980      #PQR                #GHI
##                 26410      #STU  #JKL
##                 30780      #WVX  #MNO
##                 35180];    #YZa  #PQR     #rows

##sampleYs = [            
##       0
##    4280
##    8630
##   13000
##   17500
##   21800
##                 ];        #rows
##sampleYs = [       100      #ABC
##                  4380      #DEF
##                  8730      #GHI
##                 13300      #JKL
##                 17800      #MNO
##                 22100      #PQR
##                 ];        #rows


#end of config

sampleYs += ceil(skipMM/25.4 * dpi);

#generate coords array 
[m, n] = ndgrid(sampleXs, sampleYs);
sample_coords = [m(:), n(:), ones(length(sampleYs)*length(sampleXs), 2) .* sampleSize];

pkg load image

# load source file list
filenames = dir(input_directory);

# create output dirs
mkdir(output_directory);
##mkdir([output_directory 'images']);
  
for sample=3:size(filenames)(1)
  
  #start measuring process time for this sample
  tic;
  
  # check if file is not a directory
  if isfolder([input_directory filenames(sample).name])
    continue
  endif

  # get sample name from filename  
  filename = filenames(sample, 1);
  [~, basename, ext] = fileparts ([input_directory filename.name]);
  
  #get hole diameter (px) from filename
  holeRad = str2num(basename(7:8))/254*dpi/2;
  
  printf("%s: ", [basename ext]);
  
  #check if output file exists. If true don't process.
  file_exists = exist([output_directory basename char(asciiNumTable(1)) '.png']);
  
  if file_exists == 2
   string = sprintf("Output exists!\n");
   printf("%s", string);
   continue
  endif 
  
  #load sample
  im_highRes = imread([input_directory '/' basename ext]);
##  
##  #convert source to grayscale
##  gr_highRes = cv.cvtColor(im_highRes, 'RGB2GRAY');

##  #load and convert to grayscale
##  gr_highRes = cv.cvtColor(imread([input_directory '/' basename ext]), 'RGB2GRAY');
  
##  #find cut off colour (grayscale value too bright to be a hole)
##  histogram = imhist(gr_highRes);
##  
##  [~, firstPeak] = max(histogram(1:30));
##  [~, secondPeak] = max(histogram(50:256));
##  secondPeak += 49;
  
  #TODO:
  # find secondPeak, find FIRST local minimum on the left and use it as max in 
  # firstPeak lookup
  
##  [~, tr] = min(histogram(firstPeak:secondPeak));
##  tr += firstPeak - 1;
##  
  #uncomment for lacquered speciments:
##  tr = 63;
  
##  #preparing and saving plot of imhist
##  figure('visible','off'), plot(histogram);
##  maxh = max(histogram);
##  hold on;
##  %axis([0, 255, 0, maxh*0.25]);
##  axis([0, 255, 0, histogram(tr)*10]);
##  line("xdata", [firstPeak, firstPeak], "ydata", [0, maxh], "linewidth", 3);
##  line("xdata", [secondPeak, secondPeak], "ydata", [0, maxh], "linewidth", 3);
##  line("xdata", [tr, tr], "ydata", [0, maxh], "linewidth", 1);
##  hold off;
##  print([output_directory 'images/hist_' basename '.png']);
  
  #filtering original grayscale image
##  mask = (gr_highRes > tr)*255;
##  bw_gray = gr_highRes .+ mask;
##  bw_gray = gr_highRes .+ (gr_highRes > tr)*255;
##  
  #cut and save samples
  for i=1:size(sample_coords)(1)
    printf("%s ", char(asciiNumTable(i)));
    im_crop = imcrop(im_highRes, sample_coords(i, :));
    
    #add top and left margin if sample does not fit into image (if holes are very 
    # close to image's border
##    [grH grW] = size(im_crop);
##    imgMargin = ceil(holeRad+holeRadAdd);
##    
##    marginTop = ones(imgMargin, grW) * 255;
##    marginLeft = ones(grH + imgMargin, imgMargin) * 255;
##    
##    im_crop = [marginTop; im_crop];
##    im_crop = [marginLeft im_crop];
    
    imwrite(im_crop, [output_directory basename char(asciiNumTable(i)) '.png']);
  endfor

  # return sample generation time
  printf("\t%d\n", toc);
endfor

printf(INFO);
