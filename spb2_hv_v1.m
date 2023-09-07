% HVPS log file extractor

clear all;

%path='/mnt/d/EUSO/ISS/03_2019_10_25/UV_session3/';
%path='/mnt/d/EUSO/ISS/02_2019_10_20/';
%path='/mnt/d/EUSO/ISS/05_2019_11_21/';
%path='/mnt/d/EUSO/Rome/TimeGaps/';
%path='/mnt/d/EUSO/ISS/07_2019_12_05/';
%path='/mnt/d/EUSO/ISS/08_2019_12_30/';
%path='/mnt/d/EUSO/ISS/09_2020_01_08/';
%path='/mnt/d/EUSO/ISS/11_2020_02_21/rg4860/';
%path='/mnt/d/EUSO/ISS/12_2020_03_02/rg4919/';
%path='/mnt/d/EUSO/ISS/15_2020_04_29/5419/';
%path='/mnt/d/EUSO/ISS/24/Session-24(20250820)_ISS/';
%path='~/tmp/Mini-EUSO_questions/5/Session-39(20210419)_ISS/'
%path='/mnt/d/EUSO/ISS/10/rg4508/';
%path='/home/alx/tmp/2/';
path='/home/alx/Downloads/Jacek/';
%path='./';
listing = dir([path 'hv_z1*.dat']);
records = {'TURNON', 'TURN_OFF', 'DACS_LOADED', 'SR_LOADED', 'HVPS_INTR', 'BLOCK_ECUNIT', 'BLOCK_INTR', 'UNUSED_1', 'UNUSED_2', 'UNUSED_3', 'UNUSED_4', 'HVPS_STATUS', 'OVERBRIGHT', 'SR_LOADED_HW1', 'SR_LOADED_HW2','','','','','',  '','','','','','','','','','', '','','','','','','','','','', '','','','','','','','','','', '','','','','','','','','','', '','','','','','','','','','', '','','','','','','','','','', '','','','','','','','','','', '','','','','','','','','','','NEW_FILE'};

%magic_HV = [hex2dec('5A') hex2dec('16') hex2dec('3C') hex2dec('01')];
magic_HV = [hex2dec('01') hex2dec('3C') hex2dec('16') hex2dec('5A')];

n_gtu = 0;
n_gtu_prev = 0;
n_ovr = 0;

listing = dir([path 'hv*.dat']);

for filename_cntr = 1:numel(listing)
    filename = [path listing(filename_cntr,1).name];    
    fid = fopen(filename);
    cpu_file = fread(fid, inf);
    fclose(fid);
    disp(filename);
    
    sections_HV = strfind(cpu_file',magic_HV);
    if numel(sections_HV) ~= 0
        hv_packet_len_records_u8 = uint8(cpu_file(sections_HV+4:sections_HV+7));
        %hv_packet_len_records_u32 = typecast(hv_packet_len_records_u8, 'uint32');
        hv_packet_len_records_u32 = (numel(cpu_file)-8)/16;
        hv_packet_1d_u8 = uint8(cpu_file(sections_HV+8:sections_HV+8+4*4*hv_packet_len_records_u32-1));
        hv_packet_1d_u32 = typecast(hv_packet_1d_u8, 'uint32');
        hv_packet_2d = reshape(hv_packet_1d_u32, [4 hv_packet_len_records_u32]);
        for j=1:hv_packet_len_records_u32
            channels_s4 = dec2base(bitand(hv_packet_2d(4,j), hex2dec('3ffff')), 4);
            record_type_str = cell2mat(records(1+(hv_packet_2d(3,j))));
            n_gtu_prev = n_gtu;
            n_gtu = (hv_packet_2d(1,j));
            % calculate the number of overflows
            if(n_gtu < n_gtu_prev)
                n_ovr = n_ovr + 1;
            end
            % take into account the number of overflows of uint32
            sec = uint32(double(n_gtu)*2.5/1000000 + 2^32*2.5/1000000*n_ovr);      
            time_usual = datestr(seconds(sec),'HH:MM:SS');
            if hv_packet_2d(3,j) ~= 2
                channels = strcat(repmat('0', 1,9-numel(channels_s4)), channels_s4);
                disp(sprintf('%d\t%s\t%s\t%s', (hv_packet_2d(1,j)),  datetime(hv_packet_2d(2,j),'ConvertFrom','epochtime','Format','dd-MMM-yyyy HH:mm:ss' ), cell2mat(records(1+(hv_packet_2d(3,j)))), channels));
            else
                disp(sprintf('%d\t%s\t%s\t%d\t%dV', (hv_packet_2d(1,j)),  datetime(hv_packet_2d(2,j),'ConvertFrom','epochtime','Format','dd-MMM-yyyy HH:mm:ss'), cell2mat(records(1+(hv_packet_2d(3,j)))), hv_packet_2d(4,j)/2^16, mod(hv_packet_2d(4,j),2^16)*1121/4096));
            end
        end
    end
    

end


