create or replace package MY_SITEMAP as 
 
 
-- This procedure creates a sitemap that includes all public pages 
-- in the application with p_app_id with the following exceptions: 
--   - pages that have a build option that is not set to "Include" 
--   - modal pages 
--   - pages without URL access, e.g. page 0 
--   - page 101 because it is typically the login page 
procedure page_xml(p_app_id   in number); 
 
 
-- This procedure is ** specific to an application ** that utilizes the table "MY_CATALOG." 
--  
-- 
-- This procedure creates a sitemap that includes all public pages 
-- in the application with p_app_id with the following exceptions: 
--   - pages that have a build option that is not set to "Include" 
--   - modal pages 
--   - pages without URL access, e.g. page 0 
--   - page 101 because it is typically the login page 
-- 
-- Additionally, this procedure will generate sitemap entries for a specific 
-- application and page as defined within the procedure.
-- ** Edit this procedure to change the local constant k_app_id, k_page_id and k_param_name. **
procedure catalog_xml; 
 
end;
/
 
