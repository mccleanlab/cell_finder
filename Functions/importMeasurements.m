function dataOut = importMeasurements()

dataOut = [];
[files, folder] =  uigetfile('*xlsx;*.csv','MultiSelect','on');
if ischar(files)==1
    files = {files};
end

for i = 1:length(files)
    file = files{i};
    data0 = readtable([folder file]);
    try
        dataOut = [dataOut; data0];
    catch
        disp(['ERROR: ' file]);
    end
end

