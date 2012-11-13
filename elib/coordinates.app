module elib/coordinates

  entity Coordinates {
    latitude  :: Float (default=0.0)
    longitude :: Float (default=0.0)
    accuracy  :: Float (default=0.0)
    
    function json() : JSONObject {
      var obj := JSONObject();
      obj.put("latitude", latitude);
      obj.put("longitude", longitude);
      obj.put("accuracy", accuracy);
      return obj;
    }
  }
