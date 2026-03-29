{
  gateway = "100.64.0.1";

  vms = {
    monaco = {
      vcpu = 4;
      mem = 4096;
      mac = "02:00:00:00:00:01";
      address = "100.64.0.2/24";
      vsockCid = 3;
    };
  };
}
