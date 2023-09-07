% SPB-2 TCP live mode visualizator.
% Compatible with FW versions from 4.00.00

% Задание параметров программы
clear all; 
level=1; % задать уровень триггера. / Data type {raw=1, integrated=3}
frame_step=1;
mode_2d = 0;
mode_lightcurve = 1;
  mode_fft = 0; % show FFT of light curves
  one_pixel = 0; % 0 - show lightcurves for sum of pixels in frame, 1 - show lightcurve for the specified pix.
    pixel_x = 12; pixel_y = 42; % specify pixel
mode_scurve = 0;
do_txt = 0;
  
accumulation=1;
scurve_step = 1;
n_thr = 1100;
if(level==1) accumulation = 50000; end;

fix_color_map = 0;
  colorbar_lim = 25; %установить предел цветовой шкалы / set colorbar limit
                % его надо бы сделать слайдером 
only_triggered = 0;

n_active_pixels = 64; % needed for lightcurves.


frame_size=2880; % задать число пикселей ФПУ / number of pixels on FS
num_of_frames=128; % задать число фреймов в пакете / number of frames per packet
scurve_cnt = 1;
if(level==3) num_of_frames = 100; end;

magic_A = [hex2dec('05') hex2dec('0A') hex2dec('16') hex2dec('5A') hex2dec('14') hex2dec('A0') hex2dec('05') hex2dec('00')];
magic_C = [hex2dec('03') hex2dec('0C') hex2dec('16') hex2dec('5A') hex2dec('1A') hex2dec('94') hex2dec('11') hex2dec('00')];

%% visualization
% Подготовка данных к формированию изображения

% path to directory with data files   
%path='~/Yandex.Disk/attachments/0005/';
%path='~/Yandex.Disk/tmp/1/scurvedata/';
%path='~/jemeuso/scanBench/doc/scurvedata/fifthPos/';
path='~/xil_proj/zynq_board/lftp/';
%path='/home/alx/Yandex.Disk/SINP/EUSO/SPB-2/File_samples/FW_4.07.02/Periodic_LED_0_60/';
%path='/home/alx/Yandex.Disk/SINP/EUSO/SPB-2/File_samples/FW_4.07.01/';
%path='~/tmp/7/';
%path='/home/alx/Yandex.Disk/SINP/EUSO/SPB-2/tmp/2/';
%path='/home/alx/Yandex.Disk/SINP/EUSO/SPB-2/File_samples/FW_4.00.00/spot_7ph/';
%path='~/Yandex.Disk/SINP/EUSO/SPB-2/Turin/ZynqSPB2test/Scurve__2021_11_10__13_42_36__dac7_40__UVLED_off/';
%path='/home/alx/Yandex.Disk/SINP/EUSO/SPB-2/Turin/trigger1/';
listing = dir([path 'frm_z1_d' int2str(level) '_*.dat']);


if(numel(listing) == 0)
    'No frame files in the specified folder'
    stop
end

% 2 graphics
if (mode_2d == 1)
    %figure;
    a1=subplot(7,1,1:6);
    a2=subplot(7,1,7);
end;



for filename_cntr = 1:numel(listing) % указание на номера файлов, из которых будет произведено чтение
    %цикл, выполняющийся для каждого файла. 
    
    filename = [path listing(filename_cntr,1).name];    
    pause(0.01)
    fid = fopen(filename);
    
    display(filename);
    
    cpu_file = uint8(fread(fid, inf)); %прочитать файл в память / read file to memory
    fclose(fid); %закрыть файл / close file
    size_frame_file = size(cpu_file); % опрелелить размер прочитанных данных / get data size
    clear sections_D; 
    sections_D1 = strfind(cpu_file',magic_A);
    if(sections_D1 ~= 0) sections_D(1,:) = strfind(cpu_file',magic_A); end
    sections_D3 = strfind(cpu_file',magic_C);
    sections_D(3,1:numel(sections_D3)) = sections_D3;
    %n_of_frames_in_packet = 128; 
    D_bytes=uint8(zeros(3, numel(sections_D(1,:)), 4*frame_size*num_of_frames));
    D_tt = zeros(3, numel(sections_D(1,:)), 'uint32');
    D_ngtu = zeros(3, numel(sections_D(1,:)));
    D_cath = zeros(3, numel(sections_D(1,:)), 12);
    j=level;
    for i=1:numel(sections_D(level,:))
        if (sections_D(j,i) ~= 0) || (only_triggered == 0)
            if (j==1) 
                tmp=uint8(cpu_file(sections_D(j,i)+28 : sections_D(j,i)+28+frame_size*num_of_frames-1)); 
                D_bytes(j,i,1:size(tmp)) = tmp(:);                                       
                D_ngtu(j,i) = typecast(uint8(cpu_file(sections_D(j,i)+8:sections_D(j,i)+11)), 'uint32');
                D_unixtime(j,i) = typecast(uint8(cpu_file(sections_D(j,i)+12:sections_D(j,i)+15)), 'uint32');
                D_tt(j,i) = (typecast(uint8(cpu_file(sections_D(j,i)+24:sections_D(j,i)+27)), 'uint32'))/(2^28); 
                D_ti(j,i) = bitand((typecast(uint8(cpu_file(sections_D(j,i)+24:sections_D(j,i)+27)), 'uint32')), 2^28-1)/(2^9); 
                D_mps(j,i) = bitand((typecast(uint8(cpu_file(sections_D(j,i)+24:sections_D(j,i)+27)), 'uint32')), 2^9-1);
            end
            if (j==3)
                tmp=uint8(cpu_file(sections_D(j,i)+28 : sections_D(j,i)+28+(2^(j-1))*frame_size*num_of_frames-1)); 
                D_bytes(j,i,1:size(tmp)) = tmp(:);                                       
                D_ngtu(j,i) = typecast(uint8(cpu_file(sections_D(j,i)+8:sections_D(j,i)+11)), 'uint32');
                D_unixtime(j,i) = typecast(uint8(cpu_file(sections_D(j,i)+12:sections_D(j,i)+15)), 'uint32');
                D_tt(j,i) = (typecast(uint8(cpu_file(sections_D(j,i)+24:sections_D(j,i)+27)), 'uint32'));
                D_ti(j,i) = 0;
            end
        end
    end 
    
    datasize = frame_size*num_of_frames*2^(level-1);
         
    %lightcurve_sum=zeros(128);
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

            if (mode_2d == 1)
                pause(0.01)   %задержать выполнение программы на 0.1sec 
            end    
                
            pdm_2d_rot = pdm_2d; % подготовить выходной массив для повернутых данных. Проинициализировать массив начальными данными до поворота            
            
            %pdm_2d_pc = zeros(48);
            
            for i = 1:n_ecasic % 6
                pdm_2d_pc((i-1)*8+1:i*8,:) = pdm_2d_rot((i-1)*10+3:i*10,:); %показания с прибора
                pdm_2d_ki(i,:) = (pdm_2d_rot((i-1)*10+2,:));
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
                end
                %вывести цветовую шкалу / show colorbar
            end
            
            if mode_lightcurve == 1
                if one_pixel == 0
                    lightcurvesum(current_frame)=sum(sum(pdm_2d_pc))/n_active_pixels;
                    %current_frame_global = current_frame_global + 1;
                    %lightcurvesum_global(current_frame_global) = sum(pic)/n_active_pixels;
                else
                    lightcurvesum(current_frame)=(pdm_2d_pc(pixel_y,pixel_x));
                    %current_frame_global = current_frame_global + 1;
                    %lightcurvesum_global(current_frame_global) = (pdm_2d_rot(pixel_y,pixel_x));                       
                end
            end
            
            
            fprintf('*');

             
            if do_txt == 1
                if(level==1)
                    pdm_2d_pc_rshp = reshape(int8(pdm_2d_pc), [1 48*48]);
                elseif(level==3)
                    pdm_2d_pc_rshp = reshape(int32(pdm_2d_pc), [1 48*48]);
                end
                fprintf(fid_txt, '%d ', pdm_2d_pc_rshp);
                fprintf(fid_txt, '\n');
            end         
        end
        
        fprintf('\n');     
 
       if mode_lightcurve == 1
            %plot(lightcurvesum(60:80), '.-');
            if(mode_fft == 0)
                plot(lightcurvesum, '.-');
            else
                plot(20*log(abs(fft(lightcurvesum))), '.-');
            end
            pause(0.5);
            %title(short_filename);
            %if(do_pics == 1)

            %saveas(gcf, strcat(filename, '.', string(packet),'.D',string(level), '.t.png'));
            %end;
        end            
        
    end
    %plot(D_ngtu(3,:),'.-');
    
end

if(mode_scurve==1) 
    figure;
    plot(reshape(scurve_array, n_thr/scurve_step, 2304));
end
%stop % stop the program execution



