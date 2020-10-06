function yes = isPastCrossing(crossing, position)

  yes = crossing.sign * position(crossing.coordinate)   ...
      > crossing.sign * crossing.crossing               ...
      ;

end
