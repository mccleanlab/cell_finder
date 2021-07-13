clearvars; clc; close all
function_list = dir(fullfile('C:\Users\Kieran\Documents\MATLAB\CellTracker\Functions','*.m'));
function_list = {function_list.name}';

%% My frequently used scripts

cd('E:\microscopy'); 

[f_list_run_cellfinder_in_folder,~] = matlab.codetools.requiredFilesAndProducts('run_cellfinder_in_folder.m');
f_list_run_cellfinder_in_folder = f_list_run_cellfinder_in_folder';
f_list_run_cellfinder_in_folder = get_filename_ext(f_list_run_cellfinder_in_folder);
shared_run_cellfinder_in_folder = intersect(function_list,f_list_run_cellfinder_in_folder);

[f_list_collect_measurements,~] = matlab.codetools.requiredFilesAndProducts('collect_measurements.m');
f_list_collect_measurements = f_list_collect_measurements';
f_list_collect_measurements = get_filename_ext(f_list_collect_measurements);
shared_collect_measurements = intersect(function_list,f_list_collect_measurements);

[f_list_analyze_collected_measurements,~] = matlab.codetools.requiredFilesAndProducts('analyze_collected_measurements.m');
f_list_analyze_collected_measurements = f_list_analyze_collected_measurements';
f_list_analyze_collected_measurements = get_filename_ext(f_list_analyze_collected_measurements);
shared_analyze_collected_measurements = intersect(function_list,f_list_analyze_collected_measurements);

%% Erica's frequently used scripts
cd('D:\Google Drive\Cell Asic Experiments\20210507_guanine_replicate'); 

[f_list_runCellFinder_ES,~] = matlab.codetools.requiredFilesAndProducts('runCellFinder_ES_20210507.m');
f_list_runCellFinder_ES = f_list_runCellFinder_ES';
f_list_runCellFinder_ES = get_filename_ext(f_list_runCellFinder_ES);
shared_runCellFinder_ES = intersect(function_list,f_list_runCellFinder_ES);


[f_list_analyzeMeasurements_ES,~] = matlab.codetools.requiredFilesAndProducts('analyzeMeasurements_ES_20210507.m');
f_list_analyzeMeasurements_ES = f_list_analyzeMeasurements_ES';
f_list_analyzeMeasurements_ES = get_filename_ext(f_list_analyzeMeasurements_ES);
shared_analyzeMeasurements_ES = intersect(function_list,f_list_analyzeMeasurements_ES);

%%



%%

shared_functions = vertcat(shared_run_cellfinder_in_folder, shared_collect_measurements,...
    shared_analyze_collected_measurements, shared_runCellFinder_ES,shared_analyzeMeasurements_ES) 
shared_functions = unique(shared_functions)
%% Get filename with extension from f_list
function [filename_ext] = get_filename_ext(x)

[~, filename, ext] = cellfun(@fileparts,x,'UniformOutput',false);
filename_ext = strcat(filename,ext);
end