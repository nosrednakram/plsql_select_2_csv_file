create or replace function address_string_rl_lo_pr(pidm_in number) return varchar2 as

    address varchar2(1000);

    function get_address(pidm number, address_type varchar2) return varchar2 as
        cursor max_seqno(pidm_c number, atyp_c varchar2) is
        select max(spraddr_seqno)
          from spraddr
         where spraddr_pidm = pidm_c
           and spraddr_atyp_code = atyp_c
           and sysdate <= nvl(spraddr_to_date, sysdate + 1)
           and sysdate >= nvl(spraddr_from_date - 30, sysdate - 1)
           and upper(nvl(spraddr_street_line1,'X')) not like 'PO BOX%'
           and upper(nvl(spraddr_street_line2,'X')) not like 'PO BOX%'
           and nvl(spraddr_status_ind,'X') <> 'I'
           and spraddr_stat_code = 'CO';
           
        seqno_v spraddr.spraddr_seqno%type;
        
        cursor get_address(pidm_c number, atyp_c varchar2, seqno_c number) is
        select 
              spraddr_street_line1||';'||
              decode(spraddr_street_line2,null,'',spraddr_street_line2||';')||
              decode(spraddr_street_line3,null,'',spraddr_street_line3||';')||
              spraddr_city||';'||
              spraddr_stat_code||';'||
              spraddr_zip
         from spraddr
        where spraddr_pidm = pidm_c
           and spraddr_atyp_code = atyp_c
           and spraddr_seqno = seqno_c;
        
        address_v varchar2(1000);
        
    begin
    
        open max_seqno( pidm, address_type);
        fetch max_seqno into seqno_v;
        close max_seqno;
        
        if seqno_v is null then
            return null;
        end if;
        
        open get_address( pidm, address_type, seqno_v);
        fetch get_address into address_v;
        close get_address;
        
        return address_v;
        
    end;

begin

    address := get_address(pidm_in,'RL');
    if address is not null then
        return address;
    end if;
    
    
    address := get_address(pidm_in,'LO');
    if address is not null then
        return address;
    end if;
    
    address := get_address(pidm_in,'PR');
    if address is not null then
        return address;
    end if;
    
    return null;
end;
