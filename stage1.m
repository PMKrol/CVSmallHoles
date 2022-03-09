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

### Stage one is to convert speciments images to grayscale,
### cut not-hole colours (grayscale values). no real magic done here...

# changelog: extended info, any extension support, 
#  resulting images in PNG (lossless but compress), first/lastPeak auto calculation, 
#  filename->diameter new "position", memory optim. 
#  Add left and top margin to speciments so there won't be problem
#  in next stages.
#  Move cutting stuff to stage 0.

#INFO = "After first run go to output_directory/images and check samples coords and histograms on image should be two peaks - one for holes (left one) and one for board color (right)\n firstPeak should be somewhere on the left from local minimum between two main peaks. \nsecondPeak - on the right. Change config variables if it is not. \n\nIf Your samples differs, change sample_coords. \nhint: use gimp to find coords and size or calculate it its important to remove (not include) anything that is not a hole ie. edge od sample. \n\nAlso it is good moment to do some corrections to generated images by removing glitches ie. speciment edge or non-hole blobs.\n";
INFO = "After first run go to output_directory/images and check samples coords and histograms on image should be two peaks - one for holes (left one) and one for board color (right) \n firstPeak should be somewhere on the left from local minimum between two main peaks. \nsecondPeak - on the right. Change config variables if it is not. \n\nAlso it is good moment to do some corrections to generated images by removing glitches ie. speciment edge or non-hole blobs.\nIt's very important for very small diameters (ie. 0.5 mm).\n\n";

#config 
input_directory = 'output-s0/';
output_directory = 'output-s1/';
dpi = 4800;
holeRadAdd = 50;

asciiNumTable = [65:90 97:122]; #A-Z + a-z

## TODO: convert "max(histogram(1:30));" (line 92-93) to config variables
##  constant tr option?

#end of config

pkg load image

# load source file list
filenames = dir(input_directory);

# create output dirs
mkdir(output_directory);
mkdir([output_directory 'images']);
  
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
  refHoleRad = str2num(basename(7:8))/254*dpi/2;
  
  printf("%s: ", [basename ext]);
  
  #check if output file exists. If true don't process.
  file_exists = exist([output_directory basename '.png']);
  
  if file_exists == 2
   string = sprintf("Output exists!\n");
   printf("%s", string);
   continue
  endif
  
  #load and convert to grayscale
  gr_highRes = cv.cvtColor(imread([input_directory basename ext]), 'RGB2GRAY');
  
  #find cut off colour (grayscale value too bright to be a hole)
  histogram = imhist(gr_highRes);
  
  [~, firstPeak] = max(histogram(1:40));
  [~, secondPeak] = max(histogram(50:256));
  secondPeak += 49;
  
  #TODO:
  # find secondPeak, find FIRST local minimum on the left and use it as max in 
  # firstPeak lookup
  
  [~, tr] = min(histogram(firstPeak:secondPeak));
  tr += firstPeak - 1;
  
  #uncomment for lacquered speciments:
##  tr = 63;
  
  #preparing and saving plot of imhist
  figure('visible','off'), plot(histogram);
  maxh = max(histogram);
  hold on;
  %axis([0, 255, 0, maxh*0.25]);
  axis([0, 255, 0, histogram(tr)*10]);
  line("xdata", [firstPeak, firstPeak], "ydata", [0, maxh], "linewidth", 3);
  line("xdata", [secondPeak, secondPeak], "ydata", [0, maxh], "linewidth", 3);
  line("xdata", [tr, tr], "ydata", [0, maxh], "linewidth", 1);
  hold off;
  print([output_directory 'images/hist_' basename '.png']);
  
  #filtering original grayscale image
  bw_gray = gr_highRes .+ (gr_highRes > tr) * 255;

  #add top and left margin if sample does not fit into image (if holes are very 
  # close to image's border
##  [grH grW] = size(bw_gray);
##  imgMargin = ceil(refHoleRad+holeRadAdd);
##  
##  marginTop = ones(imgMargin, grW) * 255;
##  marginLeft = ones(grH + imgMargin, imgMargin) * 255;
##  
##  bw_gray = [marginTop; bw_gray];
##  bw_gray = [marginLeft bw_gray];
  
  imwrite(bw_gray, [output_directory basename '.png']);

  # return sample generation time
  printf("%d, %d\n", tr, toc);
endfor

printf(INFO);
