### Stage4 loads results from stage3 and calculates distance in X and Y separately 
### between real holes coords and theoretical point coorinations.

### License: CC-BY
### This license lets others distribute, remix, adapt, and build upon your work, even commercially, 
### as long as they credit you for the original creation. This is the most accommodating of licenses offered. 
### https://creativecommons.org/licenses/?lang=en

### For more information check: [todo]

#config
#for painting only
lowMargin = 50;

input_directory = 'output-s3/';
output_directory = 'output-s4/';

# all points:
# 1   2   3
# 4       5
# 6   7   8
                    # X           Y
allPoints   =      [  0           0           ;
                      0           0.3*4800    ;
                      0           0.6*4800    ;
                      
                      0.3*4800    0           ;
                      0.3*4800    0.6*4800    ;
                      
                      
                      0.6*4800    0           ;
                      0.6*4800    0.3*4800    ;
                      0.6*4800    0.6*4800 ];  

#end of config

outArray = [];
pkg load image;

#create output dirs
filenames = dir(input_directory);
mkdir(output_directory);
mkdir([output_directory "images"]);

#convert all points to two arrays: reference points and test points                     
refPoints = [allPoints(1, :); allPoints(3, :); allPoints(6, :); allPoints(8, :)];
testPoints = [allPoints(2, :); allPoints(4, :); allPoints(5, :); allPoints(7, :)];

#Move points so center is in 0,0 coord.
mrP = mean(refPoints);
refPoints -= mrP;
testPoints -= mrP;

printf("X (vertical), Y - horizontal.\n");
printf("basename\tx2\ty2\tx4\ty4\tx5\ty5\tx7\ty7\ttoc\n");  

for fileno=3:length(filenames)
  #Start sample time
  tic;
  
  #Ignore folders
  if isfolder([input_directory filenames(fileno).name])
    continue
  endif
  
  #Get sample name by filename
  [~, basename, ext] = fileparts ([input_directory filenames(fileno).name]);

  #If output exists, ignore.  
  file_exists = exist([output_directory basename '.txt']);
  
  if file_exists == 2
   printf("\n%s: Output exists!\n", basename);
   continue
  endif 
  
  #Load sample, if empty - ignore.
  sample = load([input_directory basename '.txt']).sample;
  
  if size(sample) == 0
    continue;
  endif
 
  #Print sample name 
  printf("%s:\t", basename);

  #Calculate deltas (between real and theoretical coords)
  sample = convertTo2x8(sample);
  deltas = calcDeltasNew(sample);
  deltas = deltas'(:)';
   
  #This if uncomented generates images also.
  
  #Get hole radius from filename
  holeRad = str2num(basename(4:5))/254*4800/2;
  
  im_highRes = imread(['output-s1/' basename '.tiff']);
  for i=1:8
    im_highRes = cv.circle(im_highRes, [sample(i,2) sample(i,1)], holeRad+5, 'Color', 'r', 'Thickness', 3);
    
    if holeRad > 50
      im_highRes = cv.circle(im_highRes, [sample(i,2) sample(i,1)], holeRad-lowMargin, 'Color', 'r', 'Thickness', 3);
    endif
  endfor

  imwrite(im_highRes, [output_directory 'images/' basename '.tiff']);
  ### end of image creation
  
  #Print result
  outRow = [deltas, toc];
  printf("%.2f\t", outRow);
  printf("\n");
  
  #Add to cumulative file.
  outArray = [outArray; outRow];
  
  #Save to txt file.
  txt_out = [basename "\t" sprintf("%f\t", outRow)];
  fid = fopen([output_directory basename '.txt'], "w");
  fputs(fid, txt_out);
  fclose(fid);
    
endfor

save([output_directory "out.txt"], 'outArray');

printf("\n\nThat's all!\n");