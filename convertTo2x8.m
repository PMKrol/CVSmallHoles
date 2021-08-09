function arr = convertTo2x8(bc)
  for i=0:7
    arr(i+1, 1) = bc(1, i*2 + 1);
    arr(i+1, 2) = bc(1, i*2 + 2);
  endfor
endfunction
