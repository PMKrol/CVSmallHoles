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

### Stage3 is to correct circles individually - it cuts prerecognised (in stage2)
### circle (hole) and looks for coordinates again. This time by calculating „weight”
### center of black blob. If better recognition is needed, this is first place 
### to start improvements

INFO = "\nAfter this stage, go to images folder in output_directory and check if holes are recognised well. This time it is critical, so every „bad ones” txt files should be romeved (or corrected and reprocessed).\n";

#config

#How much pixels cut AROUND hole (aka how much hole can be moved from prerecognised coords).
holeRadAdd = 50;

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
   printf("\n%s: Output exists!", basename);
   continue
  endif 
  
  #Load sample txt. If it's empty, ignore.
  sample = load([input_directory basename '.txt']).outArray;
  if size(sample) == 0
    continue;
  endif
  
  #Get hole radius from filename
  holeRad = str2num(basename(4:5))/254*4800/2;
  
  #Load image also, to create image with circles for visualisation  
  im_highRes = imread([input_directory_st1 '/' basename '.tiff']);
  
  #Create visualisations and rerecognise centroids for each hole individually.
  for i=1:8
    imgMargin = holeRad+holeRadAdd;
  
    if imgMargin > sample(i*2) 
      imgMargin = sample(i*2);
    endif
    
    if imgMargin > sample(i*2 - 1)
      imgMargin = sample(i*2 - 1);
    endif
    
    im_crop = imcrop(im_highRes, [sample(i*2)-imgMargin sample(i*2-1)-imgMargin  imgMargin*2 imgMargin*2]);
   
    #Rerecognitions of hole coords.
    #Improvements can be done here! 
    [centdX centdY] = find(255 - im_crop);
    circle = [mean(centdY) mean(centdX)];
      
    #Paint and save image with new hole, for check.  
    im_crop_c = cv.circle(im_crop, circle, holeRad, 'Color', 'r', 'Thickness', 1);
    filename_out = sprintf("%simages/%s_%d%s", output_directory, basename, i, '.tiff');
    imwrite(im_crop_c, filename_out);
    
    #calculate new center coords in sample
    circle -= imgMargin;
    
    #return correction value
    printf("%s_%d: %d, %d\n", basename, i, circle(1), circle(2));
                       
    sample(i*2) += circle(1);
    sample(i*2 - 1) += circle(2);    
  endfor 
  
  #Save new values
  sample(20) = toc;
  save([output_directory basename '.txt'], 'sample'); 
   
endfor


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

printf(INFO);
