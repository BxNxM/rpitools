import re
import os
import tempfile
import shutil
from datetime import datetime

#http://man7.org/linux/man-pages/man5/fstab.5.html
class FstabRecord():
    def __init__(self, remote, mount_target, filesystem_type="auto", mount_options=["defaults"], is_dumped=0, filesystem_check_order=2):
        self.remote = remote
        self.mount_target = mount_target
        self.filesystem_type = filesystem_type
        self.mount_options = mount_options
        self.is_dumped = is_dumped
        self.filesystem_check_order = filesystem_check_order

    @classmethod
    def fromString(cls, raw_string):
        fields = raw_string.split()
        if(6 != len(fields)):
            raise TypeError("'{}' is not a valid fstab record, please check http://man7.org/linux/man-pages/man5/fstab.5.html".format(raw_string))
        self = cls(
            fields[0],
            fields[1],
            fields[2],
            fields[3].split(','),
            int(fields[4]),
            int(fields[5]),
        )
        return self
        
        
    def __str__(self):
        return "\t".join([
            self.remote,
            self.mount_target,
            self.filesystem_type,
            ','.join(self.mount_options),
            str(self.is_dumped),
            str(self.filesystem_check_order)
        ])

    # The official field names are not so readable, but we want to support the official names as well
    @property
    def remote(self):
       return self.fs_spec
    @remote.setter
    def remote(self,value):
       self.fs_spec=value

    @property
    def mount_target(self):
       return self.fs_file
    @mount_target.setter
    def mount_target(self,value):
       self.fs_file=value

    @property
    def filesystem_type(self):
       return self.fs_vfstype
    @filesystem_type.setter
    def filesystem_type(self,value):
       self.fs_vfstype=value

    @property
    def mount_options(self):
       return self.fs_mntops
    @mount_options.setter
    def mount_options(self,value):
       self.fs_mntops=value

    @property
    def is_dumped(self):
       return self.fs_freq
    @is_dumped.setter
    def is_dumped(self,value):
       self.fs_freq=value

    @property
    def filesystem_check_order(self):
       return self.fs_passno
    @filesystem_check_order.setter
    def filesystem_check_order(self,value):
       self.fs_passno=value


comment_regex = re.compile('^\s*#')
       
class Fstab():
    def __init__(self, file_path="/etc/fstab"):
        self.__dir_path__ = os.path.dirname(os.path.abspath(file_path))
        self.__file_name__ = os.path.basename(file_path)
        self.__lines__ = []
        self.__index__ = {
            'remote': {},
            'mount_target': {} 
        }
        #Method aliases (to be able to use the official names as well)
        self.getIndexByFsSpec = self.getIndexByRemote
        self.getIndexByFsFile = self.getIndexByMountTarget
        self.__insertRelativeToFsSpec__ = self.__insertRelativeToRemote__
        self.__insertRelativeToFsFile__ = self.__insertRelativeToMountTarget__
        self.insertAfterFsSpec = self.insertAfterRemote
        self.insertAfterFsFile = self.insertAfterMountTarget
        self.deleteFsSpec = self.deleteRemote
        self.deleteFsFile = self.deleteMountTarget
        with open(file_path) as file:
            for line in file:
                line = line.rstrip()
                if comment_regex.match(line) or '' == line:
                    self.__lines__.append(line)
                else:
                    record = FstabRecord.fromString(line)
                    self.__lines__.append(record)
                    self.__index__['remote'][record.remote] = len(self.__lines__) - 1
                    self.__index__['mount_target'][record.mount_target] = len(self.__lines__) - 1
    
    def __str__(self):
        result = ""
        for line in self.__lines__:
            result += "{}\n".format(str(line))
        return result
        
    def getFilePath(self):
        return os.path.join(self.__dir_path__, self.__file_name__)

    def __handleInputRecord(self, record):
        if(isinstance(record, FstabRecord)):
            pass
        elif(isinstance(record, str)):
            record = record.rstrip()
            if(comment_regex.match(record) or '' == record):
                pass
            else:
                record = FstabRecord.fromString(record)
        else:
            raise TypeError("Not a valid fstab record")
        if(isinstance(record, FstabRecord)):
            if(record.remote in self.__index__['remote'] or record.mount_target in self.__index__['mount_target']):
                raise ValueError("'{}' record is not unique".format(str(record)))
        return record

    def append(self, record):
        record = self.__handleInputRecord(record)
        self.__lines__.append(record)
        if(isinstance(record, FstabRecord)):
            self.__index__['remote'][record.remote] = len(self.__lines__) - 1
            self.__index__['mount_target'][record.mount_target] = len(self.__lines__) - 1

    def insert(self, index, record):
        record = self.__handleInputRecord(record)
        self.__lines__.insert(index, record)
        for index_type in self.__index__.keys():
            for key, index_value in self.__index__[index_type].items():
                if index_value >= index:
                    self.__index__[index_type][key]+=1
        if(isinstance(record, FstabRecord)):
            self.__index__['remote'][record.remote] = index
            self.__index__['mount_target'][record.mount_target] = index

    def delete(self, index):
        record = self.__lines__.pop(index)
        delete_this = {}
        for index_type in self.__index__.keys():
            delete_this[index_type] = set()
            for key, index_value in self.__index__[index_type].items():
                if index_value > index:
                    self.__index__[index_type][key]-=1
                elif index_value == index:
                    delete_this[index_type].add(key)
        for index_type in delete_this.keys():
            for key in delete_this[index_type]:
                del(self.__index__[index_type][key])
        return record

    def overwrite(self, index, record):
        original_record = self.delete(index)
        self.insert(index, record)
        return original_record

    def update(self, index, new_values):
        if not isinstance(new_values, dict):
            raise ValueError("'new_valkues' has to be a dictionary")
        new_remote = new_values.get('remote', new_values.get('fs_spec', self.__lines__[index].remote))
        new_mount_target = new_values.get('mount_target', new_values.get('fs_file', self.__lines__[index].mount_target))
        new_filesystem_type = new_values.get('filesystem_type', new_values.get('fs_vfstype', self.__lines__[index].filesystem_type))
        new_mount_options = new_values.get('mount_options', new_values.get('fs_mntops', self.__lines__[index].mount_options))
        new_is_dumped = new_values.get('is_dumped', new_values.get('fs_freq', self.__lines__[index].is_dumped))
        new_filesystem_check_order = new_values.get('filesystem_check_order', new_values.get('fs_passno', self.__lines__[index].filesystem_check_order))
        return self.overwrite(index, FstabRecord(new_remote, new_mount_target, new_filesystem_type, new_mount_options, new_is_dumped, new_filesystem_check_order))

    def length(self):
        return len(self.__lines__)

    def getLineByIndex(self, index):
        return self.__lines__[index]

    def getIndexByRemote(self, remote):
        return self.__index__['remote'][remote]

    def getIndexByMountTarget(self, mount_target):
        return self.__index__['mount_target'][mount_target]

    def __insertRelativeToRemote__(self, remote, record, shift):
        index = self.getIndexByRemote(remote) + shift
        if(index < 0):
            index = 0
        self.insert(index, record)

    def __insertRelativeToMountTarget__(self, mount_target, record, shift):
        index = self.getIndexByMountTarget(mount_target) + shift
        if(index < 0):
            index = 0
        self.insert(index, record)

    def insertAfterRemote(self, remote, record):
        self.__insertRelativeToRemote(remote, record, 1)

    def insertAfterMountTarget(self, mount_target, record):
        self.__insertRelativeToMountTarget__(mount_target, record, 1)

    def insertBeforeRemote(self, remote, record):
        self.__insertRelativeToRemote__(remote, record, 0)

    def insertBeforeMountTarger(self, mount_target, record):
        self.__insertRelativeToMountTarget__(mount_target, record, 0)

    def deleteRemote(self, remote):
        index = self.getIndexByRemote(remote)
        return self.delete(index)

    def deleteMountTarget(self, mount_target):
        index = self.getIndexByMountTarget(mount_target)
        return self.delete(index)

    def save(self):
        fd, temp_path = tempfile.mkstemp(prefix='.{}-'.format(self.__file_name__), dir=self.__dir_path__, text=True)
        file = open(temp_path, 'w')
        file.write(str(self))
        file.close()
        os.close(fd)
        original_premissions = os.stat(self.getFilePath()).st_mode
        os.chmod(temp_path, original_premissions)
        d = datetime.now()
        timestamp = '{:%Y_%m_%d-%H_%M_%S.%f}'.format(d)
        backup = os.path.join(self.__dir_path__, '.{}.{}'.format(self.__file_name__, timestamp))
        os.rename(self.getFilePath(), backup)
        os.rename(temp_path, self.getFilePath())
