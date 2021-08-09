function deltas = calcDeltasNew(sample)
  
  # all points:
  # 1   2   3
  # 4       5
  # 6   7   8
  
  #refPoints:
  # 1       3
  #          
  # 6       8
  
  #testHoles:
  #     2   
  # 4       5
  #     7   
  
  ### theoretical coords of hole 2 is calculated as mean of 1 and 3
  ### theoretical coords of hole 4 is calculated as mean of 1 and 6
  ### theoretical coords of hole 5 is calculated as mean of 3 and 8
  ### theoretical coords of hole 7 is calculated as mean of 6 and 8
  
  refPoints = [ mean([sample(1, :); sample(3, :)]);
                mean([sample(1, :); sample(6, :)]);
                mean([sample(3, :); sample(8, :)]);
                mean([sample(6, :); sample(8, :)])];

  testHoles = [ sample(2, :);
                sample(4, :);
                sample(5, :);
                sample(7, :)];
              
  deltas = testHoles - refPoints;  
  
endfunction
