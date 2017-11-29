class dictKey:
    def __init__(self, phase, bs, iodepth):
        self.iodepth = iodepth
        self.phase = phase
        self.blocksize = bs

    def __hash__(self):
        return hash(self.phase + self.blocksize)

    def __eq__(self, other):
        if self.phase == other.phase and self.blocksize == other.blocksize \
                and self.iodepth == other.iodepth:
            return True
        return False

    def __repr__(self):
        return "IO Depth = {0}, Current Phase={1}, Block Size={2}".format(self.iodepth, self.phase, self.blocksize)

    def __str__(self):
        return "IO Depth = {0}, Current Phase={1}, Block Size={2}".format(self.iodepth, self.phase, self.blocksize)

    def __lt__(self, other):
        if self.phase != other.phase:
            return self.phase < other.phase
        if self.iodepth == other.iodepth:
            if self.blocksize.find('k') != -1 and other.blocksize.find('k') == -1:
                return True
            elif self.blocksize.find('k') == -1 and other.blocksize.find('k') != -1:
                return False
            else:
                return int(self.blocksize[:-1]) < int(other.blocksize[:-1])
        else:
            return int(self.iodepth) < int(other.iodepth)

    def __le__(self, other):
        if int(self.iodepth) == int(other.iodepth):
            return True
        else:
            return self < other

    def __gt__(self, other):
        if self.phase != other.phase:
            return self.phase > other.phase

        if self.iodepth == other.iodepth:
            if self.blocksize.find('k') != -1 and other.blocksize.find('k') == -1:
                return False
            elif self.blocksize.find('k') == -1 and other.blocksize.find('k') != -1:
                return True
            else:
                return int(self.blocksize[:-1]) > int(other.blocksize[:-1])
        else:
            return int(self.iodpeth) > int(other.iodepth)

    def __ge__(self, other):
        if self.iodepth == other.iodepth:
            return True
        else:
            return self > other

class latType:
    def __init__(self):
        self.kind = ""
        self.unit = ""
        self.minVal = 0
        self.maxVal = 0
        self.avgVal = 0.0
        self.stdev = 0.0

    def __repr__(self):
        return "Kind={0} ({1}), MIN={2:d}, MAX={3:d}, AVG={4:f}, STDEV={5:f}".format( \
                self.kind, self.unit, self.minVal, self.maxVal, self.avgVal, self.stdev)

    def __str__(self):
        return "Kind={0} ({1}), MIN={2:d}, MAX={3:d}, AVG={4:f}, STDEV={5:f}".format( \
                self.kind, self.unit, self.minVal, self.maxVal, self.avgVal, self.stdev)

class bwType:
    def __init__(self):
        self.unit = ""
        self.minVal = 0
        self.maxVal = 0
        self.avgVal = 0.0
        self.stdev = 0.0

    def __repr__(self):
        return "Unit={0}, MIN={1:d}, MAX={2:d}, AVG={3:f}, STDEV={4:f}".format( \
                self.unit, self.minVal, self.maxVal, self.avgVal, self.stdev)

    def __str__(self):
        return "Unit={0}, MIN={1:d}, MAX={2:d}, AVG={3:f}, STDEV={4:f}".format( \
                self.unit, self.minVal, self.maxVal, self.avgVal, self.stdev)

class iopsType:
    def __init__(self):
        self.phase = ""
        self.val = 0

    def __repr__(self):
        return "Phase={0}, IOPS={2:d}.".format(self.phase, self.val)

    def __str__(self):
        return "Phase={0}, IOPS={1:d}.".format(self.phase, self.val)
