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

### Stage3 is to correct circles individually - it cuts prerecognised (in stage2)
### circle (hole) and looks for coordinates again. This time by calculating „weight”
### center of black blob. If better recognition is needed, this is first place 
### to start improvements

# changelog: remove info, remove image creation. 

##INFO = "\nAfter this stage, go to images folder in output_directory and check if holes are recognised well. This time it is critical, so every „bad ones” txt files should be romeved (or corrected and reprocessed).\n";

#config

#How much pixels cut AROUND hole (aka how much hole can be moved from prerecognised coords).
holeRadAdd = 50;
dpi = 4800;
##lowMargin = 50;

input_directory = 'output-s2/';
input_directory_st1 = 'output-s1/';
output_directory = 'output-s3/';

# end of config

pkg load image;
pkg load communications;

#Get list of txt samples
filenames = dir(input_directory);

#Create dirsmkdir(output_directory);
mkdir([output_directory 'images']);

outArray = [];

for fileno=3:length(filenames)
  
  #start measuring processing time of sample
  tic;
  
  #Ignore folders in source
  if isfolder([input_directory filenames(fileno).name])
    continue
  endif

  #Get sample name from filename  
  [~, basename, ext] = fileparts ([input_directory filenames(fileno).name]);
  
  #If file is not a txt file, ignore.
  if size(ext) != 4 || ext != ".txt"
    continue;
  endif
  
  if basename(1) == "."
    continue;
  endif  
  
  #If output txt file exists, don't process it again
  file_exists = exist([output_directory basename '.txt']);
  
  if file_exists == 2
   printf("%s: Output exists!\n", basename);
   continue
  endif 
  
  #Load sample txt. If it's empty, ignore.
  #txt file: [x1 y1, x2 y2 ... x8 y8] radMin, radMax, p, toc
  # holes no:
  #   1   2   3
  #   4       5
  #   6   7   8
  sample = load([input_directory basename '.txt']).outArray;
  if size(sample) == 0
    continue;
  endif
  
  #Get hole radius from filename
  holeRad = str2num(basename(7:8))/254*dpi/2;
  
  #Load image also, to create image with circles for visualisation  
  im_highRes = imread([input_directory_st1 '/' basename '.png']);
  
  printf("\n%s:\n\t", basename);
  printf("%d\t", sample);
  printf("\n\t");
   
  #Create visualisations and rerecognise centroids for each hole individually.
  for i=1:8
    
    imgMargin = holeRad+holeRadAdd;
    
    #im_crop = imcrop(im_highRes, [sample(i*2)-imgMarginTL sample(i*2-1)-imgMarginTL  imgMarginTL+imgMarginBR imgMarginTL+imgMarginBR]);
    im_crop = imcrop(im_highRes, [sample(i*2-1)-imgMargin sample(i*2)-imgMargin  imgMargin*2 imgMargin*2]);
   
    #Rerecognitions of hole coords.
    #Improvements can be done here! 
    [centdY centdX] = find(255 - im_crop);
    circle = [mean(centdX) mean(centdY)];
      
    #Paint and save image with new hole, for check.  
##    im_crop_c = cv.circle(im_crop, circle, holeRad, 'Color', 'r', 'Thickness', 1);
##    filename_out = sprintf("%simages/%s_%d%s", output_directory, basename, i, '.png');
##    imwrite(im_crop_c, filename_out);
    
    #calculate new center coords in sample
    circle -= imgMargin;
    
    #return correction value   !!! [x y] !!!
    printf("%d\t", circle);
                       
    sample(i*2 - 1) += circle(1);   #x
    sample(i*2) += circle(2);       #y
  endfor 
  
  #draw images with corrected circles and save it in images folder
  bw_gray = im_highRes;
  for i=1:8
    circleRad = holeRad+15;
##    if holeRad < lowMargin
##      circleRad = holeRad-lowMargin;
##    endif
      
    bw_gray = cv.circle(bw_gray, [sample(i*2-1) sample(i*2)], circleRad, 'Color', 'r', 'Thickness', 3);
    
  endfor

  imwrite(bw_gray, [output_directory 'images/' basename '.png']);
  
  printf("\n");
  printf("\t");
  printf("%d ", sample);
  
  #Save new values
  sample(20) = toc;
  save([output_directory basename '.txt'], 'sample'); 
   
endfor

printf("\n\n");

#Print all output.
filenames = dir(output_directory);

for sample=3:size(filenames)(1)
  if isfolder([input_directory filenames(sample).name])
    continue;
  endif
  
  var = load([output_directory filenames(sample).name]).sample;
  printf("%s\t", filenames(sample).name);
  printf("%d\t", var);
  printf("\n");
endfor

##printf(INFO);
