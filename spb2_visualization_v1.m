%Программа для вывода изображения, полученного с платы цифровой обработки
%данных УФ-атмосфера.

% Задание параметров программы
clear all; 
level=3; % задать уровень триггера. / Data type {raw=1, none=2 , integrated=3}
frame_step=1;
mode_2d = 0;
mode_lightcurve = 0;
mode_scurve = 1;
one_pixel = 0;
do_txt = 0;
fix_color_map = 0;  
accumulation=50000;
scurve_step = 1;
if(level==1) accumulation = 1; end;
colorbar_lim = 1; %установить предел цветовой шкалы / set colorbar limit
                % его надо бы сделать слайдером 
only_triggered = 0;

n_active_pixels = 256; % needed for lightcurves.


frame_size=2880; % задать число пикселей ФПУ / number of pixels on FS
num_of_frames=128; % задать число фреймов в пакете / number of frames per packet
scurve_cnt = 1;
if(level==3) num_of_frames = 100; end;

magic_A = [hex2dec('03') hex2dec('0A') hex2dec('16') hex2dec('5A') hex2dec('0C') hex2dec('A0') hex2dec('05') hex2dec('00')];
magic_C = [hex2dec('02') hex2dec('0C') hex2dec('16') hex2dec('5A') hex2dec('10') hex2dec('94') hex2dec('11') hex2dec('00')];

%% visualization
% Подготовка данных к формированию изображения

% path to directory with data files   
%path='~/Yandex.Disk/attachments/0005/';
%path='~/Yandex.Disk/tmp/1/scurvedata/';
%path='~/jemeuso/scanBench/doc/scurvedata/fifthPos/';
path='~/xil_proj/zynq_board/lftp/';

listing = dir([path 'frm_l' int2str(level) '_*.dat']);

% 2 graphics
if (mode_2d == 1)
    figure;
    a1=subplot(7,1,1:6);
    a2=subplot(7,1,7);
end;



for filename_cntr = 1:numel(listing) % указание на номера файлов, из которых будет произведено чтение
    %цикл, выполняющийся для каждого файла. 
    
    filename = [path listing(filename_cntr,1).name];    
    pause(0.2)
    fid = fopen(filename);
    
    display(filename);
    
    cpu_file = uint8(fread(fid, inf)); %прочитать файл в память / read file to memory
    fclose(fid); %закрыть файл / close file
    size_frame_file = size(cpu_file); % опрелелить размер прочитанных данных / get data size
    sections_D1 = strfind(cpu_file',magic_A);
    if(sections_D1 ~= 0) sections_D(1,:) = strfind(cpu_file',magic_A); end;
    sections_D3 = strfind(cpu_file',magic_C);
    sections_D(3,1:numel(sections_D3)) = sections_D3;
    %n_of_frames_in_packet = 128; 
    D_bytes=uint8(zeros(3, numel(sections_D(1,:)), 4*frame_size*num_of_frames));
    D_tt = zeros(3, numel(sections_D(1,:)));
    D_ngtu = zeros(3, numel(sections_D(1,:)));
    D_cath = zeros(3, numel(sections_D(1,:)), 12);
    for j=[1 3] % for each data type (D1 or D2 or D3)
        for i=1:numel(sections_D(level,:))
            if (sections_D(j,i) ~= 0) || (only_triggered == 0)
                tmp=uint8(cpu_file(sections_D(j,i)+20+(j==3)*4 : sections_D(j,i)+20+(j==3)*4+(2^(j-1))*frame_size*num_of_frames-1)); 
                D_bytes(j,i,1:size(tmp)) = tmp(:);                                       
                D_ngtu(j,i) = typecast(uint8(cpu_file(sections_D(j,i)+8:sections_D(j,i)+11)), 'uint32');
                D_unixtime(j,i) = typecast(uint8(cpu_file(sections_D(j,i)+12:sections_D(j,i)+15)), 'uint32');
                D_tt(j,i) = typecast(uint8(cpu_file(sections_D(j,i)+16:sections_D(j,i)+19)), 'uint32');
            end
        end 
    end
    
    datasize = frame_size*num_of_frames*2^(level-1);
         
    lightcurve_sum=zeros(128);
    for i=1:frame_step:numel(sections_D(level,:))
        if (D_tt(level,i) == 0) && (only_triggered == 1)
            continue;
        end
        fprintf('T:%d\n', i);

        frame_data = reshape(D_bytes(level,i,1:datasize), [1 datasize]); % выбрать из всех данных, полученных из файла, блок, содержащий изображение / take subarray with only image data
        if level == 3% случай триггера уровня 3
            frame_data_cast = typecast(frame_data(:), 'uint32'); %преобразовать представление данных к  uint32 // convert to uint32
        elseif level == 1% случай триггера уровня 1
            frame_data_cast = frame_data;% оставить представление данных без изменения  // leave unchanged
        end
        frames = reshape(frame_data_cast, [frame_size num_of_frames]); % перегруппировать массив из одномерного в двумерный
        
        if(do_txt == 1)
            fid_txt = fopen([filename '.L' int2str(level) '.' int2str(i) '.txt'],'wt');
        end

        % Формирование изображения на экране
        for current_frame=1:1:num_of_frames % для каждого фрейма, прочитанного из файла / for each file in directory
            %disp(current_frame); % вывести значение переменной на экран / print to log screen
            pic = double(frames(:, current_frame)')/accumulation;% выбрать один фрейм из блока данных, который содержит все фреймы / select just one frame
            dimx_ecasic = (8); %задать размер по х блока данных, выдаваемый платой ECASIC
            dimy_ecasic = (48+12);%задать размер по y блока данных, выдаваемый платой ECASIC
            n_ecasic=6;% задать количество плат ECASIC
            ecasics_2d = fliplr(reshape(pic', [dimx_ecasic dimy_ecasic n_ecasic])); % сформировать двумерный массив 8х48, содержащий изображение одного фрейма / form an array 8x48 with just one frame

            % сформировать двумерный массив 48х48, содержащий изображение одного фрейма 
            pdm_2d = [ecasics_2d(:,:,1)' ecasics_2d(:,:,2)' ecasics_2d(:,:,3)' ecasics_2d(:,:,4)' ecasics_2d(:,:,5)' ecasics_2d(:,:,6)']; % form an array 48x48 with just one frame

            pause(0.01)   %задержать выполнение программы на 0.1sec 
 
            pdm_2d_rot = pdm_2d; % подготовить выходной массив для повернутых данных. Проинициализировать массив начальными данными до поворота            
            
            %pdm_2d_pc = zeros(48);
            
            for i = 1:n_ecasic % 6
                pdm_2d_pc((i-1)*8+1:i*8,:) = pdm_2d_rot((i-1)*10+3:i*10,:); %показания с прибора
                pdm_2d_ki(i,:) = pdm_2d_rot((i-1)*10+2,:);
            end;
            
            if (mode_scurve == 1)
                scurve_array(scurve_cnt,:,:)=pdm_2d_pc;
                scurve_cnt=scurve_cnt+1;
            end
            
            %pdm_2d_pc = pdm_2d_rot;
            
            if (mode_2d == 1)
                if fix_color_map == 1                     
                    imagesc(a1,pdm_2d_pc, [0 colorbar_lim]);
                    colorbar(a1);
                    imagesc(a2,pdm_2d_ki, [0 colorbar_lim]);
                    colorbar;
                else
                    imagesc(a1,pdm_2d_pc);
                    colorbar(a1);
                    imagesc(a2,pdm_2d_ki);
                    colorbar;
                end;
                %вывести цветовую шкалу / show colorbar
            end
            fprintf('*');
           
        end
        
        fprintf('\n');     
        
    end
    %plot(D_ngtu(3,:),'.-');
    
end

if(mode_scurve==1) 
    figure;
    plot(reshape(scurve_array, 1100/scurve_step, 2304)/accumulation);
end
%stop % stop the program execution



