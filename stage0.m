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
skipMM = 0;  #16, 14, -1, -3
doRotate = 0;


#no longer applicable, calculated automatically. See line 93.
##firstPeak = 30;
##secondPeak = 110;

asciiNumTable = [65+asciiSkip:90 95 97:122];

# samples coords and sizes, coords from upper left
# for samples coords (upper left) generator
sampleSize = [4095 4095];
sampleXs = [420 5450 10500];   ;#cols

##sampleYs = [      
## #2 plates, good scan      
##     220      #ABC
##    4500      #DEF
##    8850      #GHI
##   13270      #JKL (+150)
##   17650      #MNO
##   21980      #PQR
##                 ];        #rows

##sampleYs = [      
## #1 plate, good scan      
##     220      #ABC
##    4500      #DEF
##    8850      #GHI
##                 ];        #rows

sampleYs = [     
##                                                                                                                              3 plates, good scan
     220      #ABC
    4500      #DEF
    8850      #GHI
   13270      #JKL
   17650      #MNO
   21980      #PQR
                 26410      #STU
                 30780      #WVX
                 35180];    #YZ_        #rows


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

pkg load image

# load source file list
filenames = dir(input_directory);

# create output dirs
mkdir(output_directory);
##mkdir([output_directory 'images']);

sampleYsOrig = sampleYs;
sampleXsOrig = sampleXs;
  
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
  
  lastLetter = basename(15);
  basename = basename(1:14);
    
  printf("%s: ", [basename ext]);
  
  #check if output file exists. If true don't process.
  file_exists = exist([output_directory basename char(asciiNumTable(1)) '.png']);
  
  if file_exists == 2
   string = sprintf("Output exists!\n");
   printf("%s", string);
   continue
  endif 
  
  if strcmp(lastLetter, "A")
    printf("(A) ");
    doRotate = 0;
##    skipMMy = 16;
##    skipMMy = 15.5;
##    skipMMy = 15;
    skipMMy = 14.5;
    skipMMx = 0;
  elseif strcmp(lastLetter, "B")
    printf("(B) ");
    doRotate = 1;
##    skipMMy = 0.7;
    skipMMy = 1.0;
##    skipMMx = 1.8;
    
  elseif strcmp(lastLetter, "C")
    printf("(C) ");
    doRotate = 1;
##    skipMMy = 0.1;
    skipMMy = 3; #if scan starts not in 0 (Lide200 problem)
    skipMMx = -1.6;
  
  elseif strcmp(lastLetter, "D")
    printf("(D) ");
    doRotate = 0;
##    skipMMy = 16;
##    skipMMy = 15.25;
    skipMMy = 15.5;
##    skipMMy = 14;
##    skipMMx = 2.1; #05
##    sampleXsOrig = [420 5450 10250];
##    skipMMx = 3.75;
##    sampleXsOrig = [420 5450 10300];
##    skipMMx = 3.75;
    skipMMx = 4;
    sampleXsOrig = [420 5450 10300];
  else
    printf("No letter?");
  endif
  
  #die();
    
  sampleYs = sampleYsOrig + ceil(skipMMy/25.4 * dpi);
  sampleXs = sampleXsOrig + ceil(skipMMx/25.4 * dpi);
  
  #generate coords array 
  [m, n] = ndgrid(sampleXs, sampleYs);
  sample_coords = [m(:), n(:), ones(length(sampleYs)*length(sampleXs), 2) .* sampleSize];
    
  #load sample
  im_highRes = imread([input_directory '/' basename lastLetter ext]);
  
  if doRotate
    im_highRes = imrotate(im_highRes, 180);
  endif
  
  #cut and save samples
  for i=1:size(sample_coords)(1)
    printf("%s ", char(asciiNumTable(i)));
    im_crop = imcrop(im_highRes, sample_coords(i, :));
    
    imwrite(im_crop, [output_directory basename char(asciiNumTable(i)) lastLetter '.png']);
  endfor

  # return sample generation time
  printf("\t%d\n", toc);
endfor

printf(INFO);
