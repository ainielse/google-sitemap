create or replace package body MY_SITEMAP as 

function extra_stuff return varchar2 as
l_host_name     varchar2(4000) :=  APEX_UTIL.HOST_URL (p_option => null);
l_host_script   varchar2(4000) :=  APEX_UTIL.HOST_URL (p_option => 'SCRIPT');
l_script        varchar2(400);
l_pattern       varchar2(400);
l_extra_stuff   varchar2(400);

begin

  select pattern
    into l_pattern
    from user_ords_schemas
    where rownum = 1;

  l_script := replace(l_host_script, l_host_name, null);

  l_extra_stuff := substr(l_script, instr(l_script, l_pattern) );

  return l_extra_stuff;

end extra_stuff;
 
-- create an apex session
procedure create_apex_session(p_app_id  in number) as

l_any_page_id  number;
begin 

  select page_id
    into l_any_page_id
    from APEX_APPLICATION_PAGES
    where application_id = p_app_id
      and rownum = 1;

  apex_session.create_session (
    p_app_id   => p_app_id,
    p_page_id  => l_any_page_id,
    p_username => 'SITEMAP_USER' );

end create_apex_session;
 
-- see package spec for usage 
procedure page_xml (p_app_id  in number) as 
 
l_xml       xmltype; 
l_any_page  number;
l_host      varchar2(4000) := APEX_UTIL.HOST_URL (p_option => null);
l_extra_stuff    varchar2(4000) := extra_stuff;
 
begin 

  create_apex_session(p_app_id => p_app_id);

  begin 
    select   
      xmlElement("urlset", xmlattributes('http://www.sitemaps.org/schemas/sitemap/0.9' as "xmlns") 
        , xmlAgg( 
          xmlElement("url", 
            --xmlElement("loc", APEX_UTIL.HOST_URL (p_option => null) || '/apex/f?p=' || aap.application_id ||':'|| aap.page_id ||':0') the_xml 
            xmlElement("loc",  l_host|| replace(apex_util.prepare_url('f?p=' || aap.application_id ||':'|| aap.page_id ||':'), l_extra_stuff, null)) the_xml
            ) 
          ) 
        ) the_xml 
    into l_xml 
    from apex_applications aa 
    inner join APEX_APPLICATION_PAGES aap on aap.application_id = aa.application_id 
    left outer join apex_application_build_options bo  
       on bo.build_option_name = aap.build_option 
      and bo.application_id = aap.application_id 
    where aa.application_id = p_app_id 
      -- do not return modal pages 
      and aap.page_mode = 'Normal' 
      -- only show public pages 
      and (aap.page_requires_authentication = 'No' or aa.authentication_scheme_type = 'No Authentication') 
      -- do not return pages without URL access, e.g. page 0 
      and aap.page_access_protection != 'No URL Access' 
      -- do not return login page 
      and aap.page_id not in (101) 
      -- check build status 
      and (bo.build_option_status is null or bo.build_option_status = 'Include'); 
 
 
   
    htp.p('<?xml version="1.0" encoding="UTF-8"?>'); 
 
    -- Note! This will only output 32K. 
    --       If you anticipate more than 32K, consider chunking or other options. 
    htp.p(l_xml.getClobVal()); 
 
  exception 
    when others then htp.p('Err: ' || sqlerrm); 
    raise; 
  end; 
 
end page_xml; 
 
 
-- 
-- 
-- see package spec for usage 
procedure catalog_xml as 
 
k_app_id        constant integer  := 141039; 
l_host          varchar2(4000) := APEX_UTIL.HOST_URL (p_option => null);
l_extra_stuff   varchar2(4000) := extra_stuff;
l_xml           xmltype; 
 
begin 

  create_apex_session(p_app_id => k_app_id);

  begin 
    select   
      xmlElement("urlset", xmlattributes('http://www.sitemaps.org/schemas/sitemap/0.9' as "xmlns") 
        -- URLs for all the standard (not parameterized pages) 
        , (select xmlAgg( 
            xmlElement("url", 
              xmlElement("loc",  l_host|| replace(apex_util.prepare_url('f?p=' || aap.application_id ||':'|| aap.page_id ||':'), l_extra_stuff, null)) the_xml
              ) 
            ) 
              from apex_applications aa 
              inner join APEX_APPLICATION_PAGES aap on aap.application_id = aa.application_id 
              left outer join apex_application_build_options bo  
                 on bo.build_option_name = aap.build_option 
                and bo.application_id = aap.application_id 
              where aa.application_id = k_app_id 
                -- do not return modal pages 
                and aap.page_mode = 'Normal' 
                -- only show public pages 
                and (aap.page_requires_authentication = 'No' or aa.authentication_scheme_type = 'No Authentication') 
                -- do not return pages without URL access, e.g. page 0 
                and aap.page_access_protection != 'No URL Access' 
                -- do not return login page 
                and aap.page_id not in (101, 3)  -- <== list of pages not to return. Page 3 is included because it is handled below.
                -- check build status 
                and (bo.build_option_status is null or bo.build_option_status = 'Include') 
            ) 
        -- URLs for the parameterized page k_page_id   
        -- ** repeat this section for each parameterized page **
        , (select xmlAgg( 
            xmlElement("url", 
                     xmlElement("loc",  l_host|| replace(apex_util.prepare_url('f?p=' || k_app_id ||':'|| 3 
                     ||':::::'||'P3_PRODUCT_ID'||':' || mc.product_id), l_extra_stuff, null)) -- <=== change this
                 ) 
                 ) 
               from demo_product_info mc  -- <=== change this
              )    
        -- ** end of repeated section
        ) the_xml 
    into l_xml 
    from dual; 
 
 
   
    htp.p('<?xml version="1.0" encoding="UTF-8"?>'); 
 
    -- Note! This will only output 32K. 
    --       If you anticipate more than 32K, consider chunking or other options. 
    htp.p(l_xml.getClobVal()); 
 
  exception 
    when others then htp.p('Err: ' || sqlerrm); 
    raise; 
  end; 
 
end catalog_xml; 
 
 
end;
/
 
