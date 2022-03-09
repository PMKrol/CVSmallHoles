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

### Stage two is to recognise eight circles (holes) in each sample using
### OpenCV HoughCircles function and write it to txt file. 

# changelog: remove info, remove image creation.

#no longer needed
#INFO = "After first run check images folder and each sample. If any circle in sample is recognised VERY bad (ie. not hole but dirt is marked), remove corresponding txt file and go to stage3. It is also possible to remove (losslessly, ie. with GIMP) dirt from source folder's sample, so it won't be recognised again. If so, remove corresponding txt file and rerun stage2. \nDue to stage three (which suppose to improve recognition) stage2 is not very critical to be accurate.\n";

# config
input_directory = 'output-s1/';
output_directory = 'output-s2/';
dpi = 4800;

#Hole size - lowMargin gives minimum hole size for HoughCircles function
# but not smaller than min_hole_size
low_margin = 50;
min_hole_size = 20;

#For image crop: imcrop(Image, [x y 20 20]) - would crop an image of 20x20 pixels starting from the (x,y) coordinate.
#* image dimensions
spec = [0 0 1 0.33 1;     # 0x0     -----   (top)
        0 0 0.33 1 0;     # 0x0     |       (left)
        0.66 0 0.33 1 0;  # 0.66x0      |   (right)
        0 0.66 1 0.33 1];  # 0x0.66  _____   (bottom)

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
  printf("%s:\t", basename);
  
  #get hole diameter (px) from filename
  refHoleRad = str2num(basename(7:8))/254*dpi/2;
  testHoleRad = str2num(basename(10:11))/254*dpi/2;
    
  #check if output file exists. If true don't process.
  file_exists = exist([output_directory basename '.txt']);
  
  if file_exists == 2
   printf("Output exists!\n");
   continue
  endif 
  
  #load sample image and find eight circles
  bw_gray = imread([input_directory basename '.png']);
  bw_size = size(bw_gray);
  
  deltas = [];
  
  for crp = 1:rows(spec)
    imcrop_arr = round(spec(crp, 1:4) .* [bw_size bw_size]);
    bw_crop = imcrop(bw_gray, imcrop_arr);
    
    #findReferenceHoles(image, refDiam, testDiam, vh)
    refHoles = findReferenceHoles(bw_crop, refHoleRad, testHoleRad, spec(crp, 5));
    
    for rh = 1:2
      refHoles(rh, :) = refHoles(rh, :) .+ improveHole(bw_crop, refHoles(rh, :), refHoleRad);
      bw_crop = cv.circle(bw_crop, refHoles(rh, :), refHoleRad+15, 'Color', 'r', 'Thickness', 3);
    endfor
    
    delta = improveHole(bw_crop, mean(refHoles), testHoleRad);
    printf("%d\t", delta);
    
    deltas = [deltas, delta];

    #paint circle around detected hole    
    bw_crop = cv.circle(bw_crop, mean(refHoles) + delta, testHoleRad+15, 'Color', 'r', 'Thickness', 3);
    
    #paint cross - marks where hole should be
    bw_crop = cv.line(bw_crop, mean(refHoles) - [testHoleRad/2 0], mean(refHoles) + [testHoleRad/2 0], 'Color', 'b', 'Thickness', 3);
    bw_crop = cv.line(bw_crop, mean(refHoles) - [0 testHoleRad/2], mean(refHoles) + [0 testHoleRad/2], 'Color', 'b', 'Thickness', 3);
    
    #bw_crop = cv.insertText(bw_crop, [0 0], sprintf("(%d, %d)", delta));
    bw_crop = cv.putText(bw_crop, sprintf("(%d, %d)", delta), [(imcrop_arr(3)/2-50) 50], 'Color', 'r', 'Thickness', 2);
    
    imwrite(bw_crop, [output_directory 'images/' basename num2str(crp) '.png']);
  endfor
  
  save([output_directory basename '.txt'], 'deltas');
  
  printf("%d\n", toc);
  
  
  ## [x1 y1, x2 y2 ... x8 y8] radMin, radMax, p, toc
  #outArray = eightCirclesArray(bw_gray, holeRad-lowMargin, holeRad+15);
  
##  if outArray == -1
##   string = sprintf("\n%s: Error detecting holes!\n", basename);
##   printf("%s", string);
##   continue
##  endif
##  
##  #if failed, continue
##  if size(outArray)(1) == 0 
##    printf("\n%s failed.", basename);
##    continue;
##  endif
##
##  #save output to txt file: [x1 y1, x2 y2 ... x8 y8] radMin, radMax, p, toc
##  # holes no:
##  #   1   2   3
##  #   4       5
##  #   6   7   8
##  save([output_directory basename '.txt'], 'outArray'); 
##  
##  #draw images with recognised circles and save it in images folder
##  for i=1:8
##    circleRad = holeRad+15;
##    if holeRad < lowMargin
##      circleRad = holeRad-lowMargin;
##    endif
##      
##    bw_gray = cv.circle(bw_gray, [outArray(i*2-1) outArray(i*2)], circleRad, 'Color', 'r', 'Thickness', 3);
##    
##  endfor
##
##  imwrite(bw_gray, [output_directory 'images/' basename '.png']);
##  
##  #print timings
##  string = sprintf("\n%s: ok in %d s.", basename, toc);
##  printf("%s", string);
  
endfor

###print all samples
##printf("X - array ROW, Y - array COLUMN.\n");
##printf("basename\tx1\ty1\tx2\ty2\tx3\ty3\tx4\ty4\tx5\ty5\tx6\ty6\tx7\ty7\tx8\ty8\tradMin\tradMax\tpara2\ttoc\n");
##
##filenames = dir(output_directory);
##
##for sample=3:size(filenames)(1)
##  [~, basename, ext] = fileparts ([input_directory filenames(sample).name]);
##  
##  if isfolder([input_directory filenames(sample).name]) 
##    continue;
##  endif
##  
##  if size(ext) != 4 || ext != ".txt"
##    continue;
##  endif
##  
##  if basename(1) == "."
##    continue;
##  endif  
##  
##  var = load([output_directory filenames(sample).name]).outArray;
##  printf("%s\t", filenames(sample).name);
##  printf("%d\t", var);
##  printf("\n");
##endfor
##
####printf("\nDONE!\n\n");
####printf("INFO");
