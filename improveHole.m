function holeDelta = improveHole(image, holeArr, holeRad)
  #config
  maxCorrection = 50;   #todo
  #end of config
  
  fromCenter = maxCorrection + holeRad/2;
  
  cropArray = [holeArr(1) - fromCenter, holeArr(2) - fromCenter, 2*fromCenter,  2*fromCenter];
  
  imCropped = imcrop(image, cropArray);
  
  #Rerecognitions of hole coords.
  #Improvements can be done here! 
  [centdY centdX] = find(255 - imCropped);
  hole = [mean(centdX) mean(centdY)];
  
  holeDelta = hole - fromCenter - 1;
  
endfunction
