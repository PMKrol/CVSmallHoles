### MIT License
### 
### Copyright (c) 2021 Patryk Maciej Król
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

### Stage two is to recognise eight circles (holes) in each sample using
### OpenCV HoughCircles function and write it to txt file. 

INFO = "After first run check images folder and each sample. If any circle in sample is recognised VERY bad (ie. not hole but dirt is marked), remove corresponding txt file and go to stage3. It is also possible to remove (losslessly, ie. with GIMP) dirt from source folder's sample, so it won't be recognised again. If so, remove corresponding txt file and rerun stage2. \nDue to stage three (which suppose to improve recognition) stage2 is not very critical to be accurate.\n";

# config
input_directory = 'output-s1/';
output_directory = 'output-s2/';

#Hole size - lowMargin gives minimum hole size for HoughCircles function
# but not smaller than min_hole_size
low_margin = 50;
min_hole_size = 20;

# end of config

#load file list
filenames = dir(input_directory);

#create output dirs
mkdir(output_directory);
mkdir([output_directory "images"]);

pkg load image;

for sample=3:size(filenames)(1)
  
  #start measuring time of processing sample
  tic;
  
  #copy config values
  lowMargin = low_margin;
  minimumHoleSize = min_hole_size;
  
  #ignore folders
  if isfolder([input_directory filenames(sample).name])
    continue
  endif

  #get sample name from filename
  [~, basename, ext] = fileparts ([input_directory filenames(sample).name]);
  
  #get hole diameter (px) from filename
  holeRad = str2num(basename(4:5))/254*4800/2;
  
  #calculate new lowMargin if it is too big
  if holeRad-lowMargin < minimumHoleSize
    lowMargin = holeRad - minimumHoleSize;
  endif
    
  #check if output file exists. If true don't process.
  file_exists = exist([output_directory basename '.txt']);
  
  if file_exists == 2
   string = sprintf("\n%s: Output exists!\n", basename);
   printf("%s", string);
   continue
  endif 
  
  #load sample image and find eight circles
  bw_gray = imread([input_directory basename '.tiff']);
  outArray = eightCirclesArray(bw_gray, holeRad-lowMargin, holeRad+15);
  
  #if failed, continue
  if size(outArray)(1) == 0 
    printf("\n%s failed.", basename);
    continue;
  endif

  #save output to txt file  
  save([output_directory basename '.txt'], 'outArray'); 
  
  #draw images with recognised circles and save it in images folder
  for i=1:8
    bw_gray = cv.circle(bw_gray, [outArray(i*2) outArray(i*2 - 1)], holeRad+15, 'Color', 'r', 'Thickness', 3);
    
    if holeRad < lowMargin
      bw_gray = cv.circle(bw_gray, [outArray(i*2) outArray(i*2 - 1)], holeRad-lowMargin, 'Color', 'r', 'Thickness', 3);
    endif
  
  endfor

  imwrite(bw_gray, [output_directory 'images/' basename '.tiff']);
  
  #print timings
  string = sprintf("\n%s: ok in %d s.", basename, toc);
  printf("%s", string);
  
endfor

#print all samples
printf("X - array ROW, Y - array COLUMN.\n");
printf("basename\tx1\ty1\tx2\ty2\tx3\ty3\tx4\ty4\tx5\ty5\tx6\ty6\tx7\ty7\tx8\ty8\tradMin\tradMax\tpara2\ttoc\n");

filenames = dir(output_directory);

for sample=3:size(filenames)(1)
  [~, basename, ext] = fileparts ([input_directory filenames(sample).name]);
  
  if isfolder([input_directory filenames(sample).name]) 
    continue;
  endif
  
  if size(ext) != 4 || ext != ".txt"
    continue;
  endif
  
  if basename(1) == "."
    continue;
  endif  
  
  var = load([output_directory filenames(sample).name]).outArray;
  printf("%s\t", filenames(sample).name);
  printf("%d\t", var);
  printf("\n");
endfor

printf("\nDONE!\n\n");
printf("INFO");
