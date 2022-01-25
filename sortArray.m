function sortedArray = sortArray(arrayToSort)
  #sorts array so holes should be in this order:
  #   1   2   3
  #   4       5
  #   6   7   8
 
  arr = sortrows(arrayToSort, 2);   #sort by y
  
  #sort by x
  sortedArray = sortrows(arr(1:3, :), 1);
  sortedArray = [sortedArray; sortrows(arr(4:5, :), 1)];
  sortedArray = [sortedArray; sortrows(arr(6:8, :), 1)];
  
endfunction
