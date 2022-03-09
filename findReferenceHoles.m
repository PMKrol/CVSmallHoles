function circlesArray = findReferenceHoles(image, refDiam, testDiam, vh)
  #config
  minimumHoleSize = 20;
  lowMargin = 50;
  radMaxAdd = 15;
  #end of config
  
  if refDiam > testDiam
    radMin = refDiam - (refDiam-testDiam)/2;
  else
    radMin = refDiam - lowMargin;
    
    #calculate new lowMargin if it is too big
    if radMin < minimumHoleSize
      radMin = minimumHoleSize;
    endif
      
  endif
  
  radMax = refDiam + radMaxAdd;
  
  if refDiam == testDiam
    holesNo = 3;
  else
    holesNo = 2;
  endif
    
  #tries to find 8 circles, lowering param2  
  for p = 35:-1:10
    tic;
    circles = cv.HoughCircles(image, 
                            'MinRadius', radMin,
                            'MaxRadius', radMax,
                            #'Param1', param1, 
                            'Param2', p,
                            'MinDist', 1000
                            #'DP', 1
                       );  
    
    if(size(circles)(2) == holesNo)
      for hole=1:holesNo
        circlesArray(hole, 1) = circles{hole}(1);  #x
        circlesArray(hole, 2) = circles{hole}(2);  #y
      endfor
      
      #vh = 1 - horizontal,
      #vh = 0 - vertical
      if vh == 1
        circlesArray = sortrows(circlesArray, 1);
      else
        circlesArray = sortrows(circlesArray, 2);
      endif
      
      if holesNo == 3
        circlesArray = [circlesArray(1,:); circlesArray(3, :)];
      endif
      
      return;
              
    endif
    
  endfor
  
endfunction
