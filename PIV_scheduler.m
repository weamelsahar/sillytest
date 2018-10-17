%% PIV_scheduler
%   Introduction:
%   This piece of Matlab script can be used to schedule PIV (particle image
%   velocimetry) vector feild extraction. The code implements a C based ex-
%   ecutable for vector feild image extraction developed in Von Karman ins-
%   titute by F.Scarano "widim33_2.exe".(To be used only at the University-
%   of Bristol) You have to place "widim33_2.exe" in the same folder along-
%   with this script POV_scheduler.
%   Please refer to (r.theunissen@bristol.ac.uk, from:F.Scarano@tudelft.nl)
%   for the latter dependency and further permissions.
%
%   Project files structures:
%   The scheduler can be used to work with projects exported from PIV meas-
%   urment tools (eg. DynamicStudio/Dantec). The project needs to be arran-
%   ged to follow the following sturcture:
%   Main_folder >>
%                  %%Run A set of case studies (eg. different flow speeds)
%                  >>10msec
%                       %% Each case study can have several feilds of view
%                       %% numbered sequentially (FOV'number')as follows.
%                       >> FOV1
%                           %% Each FOV* folder should contain another
%                           %% folder called 'Renamed' including all the
%                           %% image pairs and the maksing image according
%                           %% "widim33_2.exe" designated formatting(Refer
%                           %% to "widim33_2.exe" readme file).
%                           %% The resulted vector feilds will be placed in
%                           %% a folder called 'Vectors' in .plt format
%                               >> Vectors
%                                     >>bs_0000.plt
%                                     >>bs_0001.plt
%                                     >>bs_000*.plt
%                       >> FOV2
%                       >> FOV*
%                  >>20msec
%                  >>**msec
%
%  Inputs:
%   MainFolder>>Run**>>FOV*>>Renamed>>*a.tif,*b.tif,mask_FOV*
%
%  Outputs:
%   MainFolder>>Run**>>FOV*>>Vectors>>bs_****.plt,
%
%  Other m-files required: Get_PIV_paths.m, sub(loop_for_folder_input)
%  Other non Matlab files required: widim33_2.exe

% Author: Weam Elsahhar
% Uinversity of Bristol
% email: we15226@bristol.ac.uk
% Website: http://www.
% May 2018; Last revision: 10-Sep-2018

%------------- BEGIN CODE --------------

clear all
close all
clc

% disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
% disp('%                                                                %');
% disp('% COPYRIGHT : WEAM ELSAHHAR - UNIVERSITY OF BRISTOL              %');
% disp('%                                                                %');
% disp('% THIS CODE REMAINS PROPERTY OF WEAM ELSAHHAR AND MAY NOT BE     %');
% disp('% DISTRIBUTED WITHOUT PRIOR CONSENT OF THE AUTHOR.               %');
% disp('%                                                                %');
% disp('% PLEASE FEEL FREE TO REPORT ANY BUGS TO :we.15226@bristol.ac.uk %');
% disp('%                                                                %');
% disp('% Bristol, July 2018                                             %');
% disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
% disp(' ');

%% Get paths:
% Get the path of the main project folder from the user and ask for includ-
% ed Runs
[Project_name,Run_name,FOV_name, Main_folder,failed]= Get_images_dir();

if failed ==1
    disp('Error:Folder selection failed')
    return;
end
doneflag=0;
my_firsttime=1; %:D
Prog_bar=waitbar(0,'Starting....');
while(doneflag~=1)

%% Get information lsiting the image pairs content of the project:
% Search for the project content of image pairs and returns files
% arrangment according to the porject structure in the definition of this
% script
[Images_a,failed]=get_tifs_a(Main_folder);
[Images_b,failed]=get_tifs_b(Main_folder);
Total_images_num=length(Images_a);
if failed ==1
    disp('Error:Images selection failed');
    return;
end

if length(Images_a) ~= length(Images_b);
   disp('Warning:Images missing from some image pairs');
%    return; 
end

[Vectors]=get_vectors(Main_folder);


%% Print out project content and completion precentage
disp([num2str(length(Images_a)),': image pairs were found']);
disp([num2str(length(Vectors)),' resolved vectors were found ....',num2str(length(Vectors)/length(Images_a)*100),'%']);



%% Remove images from list for coressponding resolved vectors
[Images_a,Images_b]=removedone(Images_a,Images_b,Vectors);

%% Create sequential cases and return group sizes for .cas files  
[groups]=sequence(Images_a);

if my_firsttime==1
    for index=1:length(groups)
        index_killed(index)=true;
    end
else
    
end

%% Create configuration .cas file for each image pair and run "widim_33_2.exe"  
% cd 'E:\PIV\PIVscheduler_v1.1'

disp('List of .cas files groups:')
for index=1:length(groups)
    if index == 1
        startimage_index=Images_a(index).name;
    else
        startimage_index=Images_a(sum(groups(1:index-1))+1).name;
    end
    if (groups(index)==1)
        endimage_temp=Images_a(sum(groups(1:index-1))+1).name;
        Lastnumber=str2double(endimage_temp(end-length('a.tif')))+1;
        if Lastnumber==10
            startimage_index(end-length('a.tif'))=num2str(Lastnumber-2);
        else
            endimage_temp(end-length('a.tif'))=num2str(Lastnumber);
        end
        
        endimage_index=endimage_temp;
    else
        endimage_index=Images_a(sum(groups(1:index))).name;
    end
        filename{index}=create_cas(Main_folder,startimage_index,endimage_index,index);
   
        disp(['Group:',num2str(index),':',startimage_index,' to ',endimage_index]);
        startimage(index)=str2double(regexp(startimage_index,'\d*','Match'));
        endimage(index)=str2double(regexp(endimage_index,'\d*','Match'));
end
for index=1:length(Images_a)
    Images_nums=str2double(regexp(Images_a(index).name,'\d*','Match'));
end

fclose('all');
if length(groups)>4
    groupstorun=4; %maximum number of groups to run
else
    groupstorun=length(groups);
end

if (groupstorun)==0
    disp('Postprocessing complete  :)')
    return
end

for index=1: groupstorun
   
    if index_killed(index)==true
       
        eval(['!start "group',Project_name,Run_name,FOV_name,num2str(index),'" .\widim33_2.exe ',Main_folder,'\',cell2mat(filename(index))]);
        pause(20);

        index_killed(index)=false;
    else
    end
end
timeout=140;
kill_flag=0;


progress=length(Vectors)/Total_images_num;
progress_message=sprintf(['PIV (',num2str(progress*100),') precent completed in\n',Project_name,':',Run_name,':',FOV_name]);
progress_message(progress_message=='_')=' ';
waitbar(progress,Prog_bar,progress_message);

while (kill_flag==0)
    Vectors1=length(get_vectors(Main_folder));
    [ last_resolved ] =get_current_end( Main_folder ,Images_nums,groups,startimage,endimage);
    disp('Start time out')
    pause(timeout);
    Vectors2=length(get_vectors(Main_folder));
    [ current_last_resolved ] = get_current_end( Main_folder,Images_nums,groups,startimage,endimage);
    
    Date_time=(clock);
    disp(['PIV timed out @', num2str(Date_time(4)),':',...
        num2str(Date_time(5)),'---',num2str(Date_time(3)), ....
        '/',num2str(Date_time(2)),'/',num2str(Date_time(1))]);
    if length(last_resolved)==length(current_last_resolved)
       for index=1:length(last_resolved)
            if isnan(last_resolved(index))&& isnan(current_last_resolved(index))
                
                fprintf(['In group:',num2str(index),' Last vector  before time out ',num2str(last_resolved(index)),'\n']);
                fprintf(['In group:',num2str(index),' Last vector  after time out ',num2str(current_last_resolved(index)),'\n']);
                fprintf(['Terminate group:',num2str(index),'\n']);
                eval(['!taskkill /FI "WindowTitle eq group',Project_name,Run_name,FOV_name,num2str(index),'"']);
                eval(['!taskkill /FI "WindowTitle eq group widim33_2.exe"']);
                eval(['!taskkill /FI "IMAGENAME eq WerFault.exe"']);
                index_killed(index)=true;
                kill_flag=1;
                
            elseif isnan(last_resolved(index))&& ~isempty(current_last_resolved(index))
                
                fprintf(['In group:',num2str(index),' Last vector  before time out ',num2str(last_resolved(index)),'\n']);
                fprintf(['In group:',num2str(index),' Last vector  after time out ',num2str(current_last_resolved(index)),'\n']);
                fprintf('Good continue\n');
                index_killed(index)=false;
            
            elseif  current_last_resolved(index)>last_resolved(index)
                
                fprintf(['In group:',num2str(index),' Last vector  before time out ',num2str(last_resolved(index)),'\n']);
                fprintf(['In group:',num2str(index),' Last vector  after time out ',num2str(current_last_resolved(index)),'\n']);
                fprintf('Good continue\n');
                index_killed(index)=false;
            
            elseif current_last_resolved(index)==endimage(index) 
            
                kill_flag=1;
            
            else
                
                fprintf(['In group:',num2str(index),' Last vector  before time out ',num2str(last_resolved(index)),'\n']);
                fprintf(['In group:',num2str(index),' Last vector  after time out ',num2str(current_last_resolved(index)),'\n']);
                fprintf(['Terminate group:',num2str(index),'\n']);
                eval(['!taskkill /FI "WindowTitle eq group',Project_name,Run_name,FOV_name,num2str(index),'"']);
                eval(['!taskkill /FI "WindowTitle eq group widim33_2.exe"']);
                eval(['!taskkill /FI "IMAGENAME eq WerFault.exe"']);
                index_killed(index)=true;
                kill_flag=1;
            
            end
        end
    else
         fprintf(['Number of groups os different from _previous number of groups \',...
         '(Probably one group finished)']);
         kill_flag=1;
    end

[Vectors_prog]=get_vectors(Main_folder);    
progress=length(Vectors_prog)/Total_images_num;
progress_message=sprintf(['PIV (',num2str(progress*100),') precent completed in\n',Project_name,':',Run_name,':',FOV_name]);
progress_message(progress_message=='_')=' ';
waitbar(progress,Prog_bar,progress_message);
end
   index_killed;
   my_firsttime=my_firsttime+1;
%    if Vectors2 < Vectors1+2
%        Date_time=(clock);
%        disp(['PIV timed out @', num2str(Date_time(4)),':',...
%            num2str(Date_time(5)),'---',num2str(Date_time(3)), ....
%            '/',num2str(Date_time(2)),'/',num2str(Date_time(1))]); 
%        for index=1:length(groups)
%            eval(['!taskkill /FI "WindowTitle eq group',Project_name,Run_name,FOV_name,num2str(index),'"']);
%        end
%       kill_flag=1;
%    end
   [Images2,failed]=get_tifs_a(Main_folder);
   disp([num2str((Vectors2)),' resolved vectors were found ....',num2str((Vectors2)/length(Images2)*100),'%']);


 if length (Vectors2)>= length(Images2)
    doneflag=1; 
 end
end