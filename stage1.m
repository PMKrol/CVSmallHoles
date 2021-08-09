### Stage one is to convert source images to grayscale,
### cut not-hole colours (grayscale values) ans split it into samples.
### no magic done here...

INFO = "After first run go to output_directory/images and check samples coords and histograms on image should be two peaks - one for holes (left one) and one for board color (right)\n firstPeak should be somewhere on the left from local minimum between two main peaks. \nsecondPeak - on the right. Change config variables if it is not. \n\nIf Your samples differs, change sample_coords. \nhint: use gimp to find coords and size or calculate it its important to remove (not include) anything that is not a hole ie. edge od sample. \n";

### License: CC-BY
### This license lets others distribute, remix, adapt, and build upon your work, even commercially, 
### as long as they credit you for the original creation. This is the most accommodating of licenses offered. 
### https://creativecommons.org/licenses/?lang=en

### For more information check: [todo]


#config 
input_directory = 'source/';
output_directory = 'output-s1/';

firstPeak = 50;
secondPeak = 125;

# samples coords and sizes, coords from upper left
                #column row size size]  
sample_coords = [ 185  512  4096 4096;
                  185 4800  4096 4096;
                  185 9096  4096 4096;
                 4915  512  4096 4096;
                 4915 4800  4096 4096;
                 4915 9096  4096 4096];
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
  
  printf("%s: ", basename)

  #load sample
  im_highRes = imread([input_directory '/' basename '.tiff']);
  
  #convert source to grayscale
  gr_highRes = cv.cvtColor(im_highRes, 'RGB2GRAY');
  
  #find cut off colour (grayscale value too bright to be a hole)
  histogram = imhist(gr_highRes);
  [~, tr] = min(histogram(firstPeak:secondPeak));
  tr += firstPeak;                               
  
  #preparing and saving plot of imhist
  figure('visible','off'), plot(histogram);
  maxh = max(histogram);
  hold on;
  axis([0, 255, 0, maxh*0.25]);
  line("xdata", [firstPeak, firstPeak], "ydata", [0, maxh], "linewidth", 3);
  line("xdata", [secondPeak, secondPeak], "ydata", [0, maxh], "linewidth", 3);
  line("xdata", [tr, tr], "ydata", [0, maxh], "linewidth", 1);
  hold off;
  print([output_directory 'images/hist_' basename '.png']);
  
  #filtering original grayscale image
  mask = (gr_highRes > tr)*255;
  bw_gray = gr_highRes .+ mask;
  
  #cut and save samples
  for i=1:size(sample_coords)(1)
    im_crop = imcrop(bw_gray, sample_coords(i, :));
    imwrite(im_crop, [output_directory basename num2str(i, "%1.0f") '.tiff']);
  endfor

  # return sample generation time
  printf("%d\n", toc);
endfor

printf(INFO);