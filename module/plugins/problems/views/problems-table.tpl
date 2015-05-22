%helper = app.helper
%datamgr = app.datamgr

%rebase layout globals(), title='All problems', js=['problems/js/img_hovering.js', 'problems/js/problems.js', 'problems/js/filters.js', 'problems/js/bookmarks.js'], css=['problems/css/problems.css', 'problems/css/perfometer.css', 'problems/css/img_hovering.css', 'problems/css/filters.css'], refresh=True, user=user

%# Look for actions if we must show them or not
%actions_allowed = True
%if app.manage_acl and not helper.can_action(user):
%actions_allowed = False
%end
<script type="text/javascript">
   var actions_enabled = {{'true' if actions_allowed else 'false'}};
   console.log('Actions: '+actions_enabled);
   function submitform() {
      document.forms["search_form"].submit();
   }

   /* Catch the key ENTER and launch the form
    Will be link in the password field
   */
   function submitenter(myfield,e){
      var keycode;
      if (window.event) keycode = window.event.keyCode;
      else if (e) keycode = e.which;
      else return true;

      if (keycode == 13){
         submitform();
         return false;
      } else {
         return true;
      }
   }

  // Typeahead: builds suggestion engine
   var hosts = new Bloodhound({
      datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      remote: {
         url: '/lookup/%QUERY',
         filter: function (hosts) {
            return $.map(hosts, function (host) { return { value: host }; });
         }
      }
   });
   hosts.initialize();
 
 
   var active_filters = [];

   // List of the bookmarks
   var bookmarks = [];
   var bookmarksro = [];

   %for b in bookmarks:
      declare_bookmark("{{!b['name']}}","{{!b['uri']}}");
   %end
   %for b in bookmarksro:
      declare_bookmarksro("{{!b['name']}}","{{!b['uri']}}");
   %end

   // We will create here our new filter options
   // This should be outside the "pageslide" div. I don't know why
   new_filters = [];
   current_filters = [];
  
   // On page loaded ...
   $(function(){
      // We prevent the dropdown to close when we go on a form into it.
      $('.form_in_dropdown').on('click', function (e) {
         e.stopPropagation()
      });

      // Typeahead: activation
      $('#filtering .typeahead').typeahead({
         hint: true,
         highlight: true,
         minLength: 1
      },
      {
         name: 'hosts',
         displayKey: 'value',
         source: hosts.ttAdapter(),
      });
    
      // Buttons tooltips
      $('span').tooltip();

      // Open the first host collapsable element
      $('.host-panel:first').addClass('in');
      
      // Hide the toolbar
      //hide_toolbar();
   });
</script>

<!-- Filtering modal dialog box -->
<div class="modal fade" id="filtering">
   <div class="modal-dialog" role="dialog" aria-labelledby="Filtering options" aria-hidden="true">
      <div class="modal-content">
         <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <h3 class="modal-title">Filtering options</h4>
         </div>
         <div class="modal-body">
            <form class="form-horizontal" role="form" name='namefilter'>
               <div class="form-group">
                  <label for="search" class="col-sm-3 control-label">Name</label>
                  <div class="col-sm-7">
                     <input class="form-control typeahead" name="search" autofocus autocomplete="off" placeholder="...">
                  </div>
                  <a class='btn btn-default col-sm-1' href="javascript:save_name_filter();"> <i class="fa fa-plus"></i> </a>
               </div>
            </form>

            <form class="form-horizontal" role="form" name='hgfilter'>
             <div class="form-group">
               <label for="hg" class="col-sm-3 control-label">Hostgroups</label>
               <div class="col-sm-7">
                 <select class="form-control" name='hg'>
                   <option value='None'> None</option>
                   %for hg in datamgr.get_hostgroups_sorted():
                   <option value='{{hg.get_name()}}'> {{hg.get_name()}} ({{len(hg.members)}})</option>
                   %end
                 </select>
               </div>
               <a class='btn btn-default col-sm-1' href="javascript:save_hg_filter();"> <i class="fa fa-plus"></i> </a>
             </div>
            </form>

            <form class="form-horizontal" role="form" name='htagfilter'>
             <div class="form-group">
               <label for="htag" class="col-sm-3 control-label">Hosts tags</label>
               <div class="col-sm-7">
                 <select class="form-control" name='htag'>
                   <option value='None'> None</option>
                   %for (t, n) in datamgr.get_host_tags_sorted():
                   <option value='{{t}}'> {{t}} ({{n}})</option>
                   %end
                 </select>
               </div>
               <a class='btn btn-default col-sm-1' href="javascript:save_htag_filter();"> <i class="fa fa-plus"></i> </a>
             </div>
            </form>

            <form class="form-horizontal" role="form" name='stagfilter'>
             <div class="form-group">
               <label for="stag" class="col-sm-3 control-label">Services tags</label>
               <div class="col-sm-7">
                 <select class="form-control" name='stag'>
                   <option value='None'> None</option>
                   %for (t, n) in datamgr.get_service_tags_sorted():
                   <option value='{{t}}'> {{t}} ({{n}})</option>
                   %end
                 </select>
               </div>
               <a class='btn btn-default col-sm-1' href="javascript:save_stag_filter();"> <i class="fa fa-plus"></i> </a>
             </div>
            </form>

            <form class="form-horizontal" role="form" name='realmfilter'>
             <div class="form-group">
               <label for="realm" class="col-sm-3 control-label">Realms</label>
               <div class="col-sm-7">
                 <select class="form-control" name='realm'>
                   %for r in datamgr.get_realms():
                   <option value='{{r}}'> {{r}}</option>
                   %end
                 </select>
               </div>
               <a class='btn btn-default col-sm-1' href="javascript:save_realm_filter();"> <i class="fa fa-plus"></i> </a>
             </div>
            </form>

            <hr/>
           
            <h4>States</h4>
            <form class="form-horizontal" role="form" name='ack_filter'>
             <div class="form-group">
               <div class="col-sm-offset-1 col-sm-9">
                 <div class="pull-left">
                   <div class="checkbox">
                     <label>
                       %if page=='problems':
                       <input name="show_ack" type="checkbox" > 
                       %else:
                       <input name="show_ack" type="checkbox" checked>
                       %end
                        Ack
                     </label>
                   </div>
                   <div class="checkbox">
                     <label>
                       <input name="show_both_ack" type="checkbox"> Both ack states
                     </label>
                   </div>
                 </div>
                 
               </div>
               <a class='btn btn-default col-sm-1' href="javascript:save_state_ack_filter();"> <i class="fa fa-plus"></i> </a>
             </div>
            </form>
           
            <form class="form-horizontal" role="form" name='downtime_filter'>
             <div class="form-group">
               <div class="col-sm-offset-1 col-sm-9">
                 <div class="pull-left">
                   <div class="checkbox">
                     <label>
                       %if page=='problems':
                       <input name="show_downtime" type="checkbox" > 
                       %else:
                       <input name="show_downtime" type="checkbox" checked>
                       %end
                        Downtime
                     </label>
                   </div>
                   <div class="checkbox">
                     <label>
                       <input name="show_both_downtime" type="checkbox"> Both downtime states
                     </label>
                   </div>
                 </div>
                 
               </div>
               <a class='btn btn-default col-sm-1' href="javascript:save_state_downtime_filter();"> <i class="fa fa-plus"></i> </a>
             </div>
            </form>

            <form class="form-horizontal" role="form" name='criticity_filter'>
             <div class="form-group">
               <div class="col-sm-offset-1 col-sm-9">
                 <div class="pull-left">
                   <div class="checkbox">
                     <label>
                       %if page=='problems':
                       <input name="show_critical" type="checkbox" > 
                       %else:
                       <input name="show_critical" type="checkbox" checked>
                       %end
                        Critical only
                     </label>
                   </div>
                 </div>
               </div>
               <a class='btn btn-default col-sm-1' href="javascript:save_state_criticity_filter();"> <i class="fa fa-plus"></i> </a>
             </div>
            </form>
         </div>
         <div class="modal-footer">
            <div id='new_search'></div>

            <a id='remove_all_filters' class='btn btn-danger pull-left' href="javascript:clean_new_search();"> <i class="fa fa-eject"></i> Remove all filters</a>
            <a id='launch_the_search' class='btn btn-primary pull-right' href="javascript:launch_new_search('/{{page}}');"> <i class="fa fa-play"></i> Launch the search!</a>
         </div>
      </div>
   </div>
</div>

    
<!-- Buttons and page navigation -->
<div class="row" style="padding: 0px;">
   <div class='col-lg-5 col-md-4 col-sm-2 pull-left'>
      <a id="hide_toolbar_btn" href="javascript:hide_toolbar()" class="btn btn-default"><i class="fa fa-minus"></i> Hide toolbar</a>
      <a id='show_toolbar_btn' href="javascript:show_toolbar()" class="btn btn-default"><i class="fa fa-plus"></i> Show toolbar</a>      
      <a id='select_all_btn' href="javascript:select_all_problems()" class="btn btn-default"><i class="fa fa-check"></i> Select all</a>
      <a id='unselect_all_btn' href="javascript:unselect_all_problems()" class="btn btn-default"><i class="fa fa-minus"></i> Unselect all</a>
      <!--<a id='expand_all' href="javascript:expand_all_block()" class="btn btn-default"><i class="fa fa-plus"></i> Expand all</a>-->
      <!--<a id='collapse_all' href="javascript:collapse_all_block()" class="btn btn-default"><i class="fa fa-minus"></i> Collapse all</a>-->
   </div>
   <div class='col-lg-7 col-md-8 col-sm-10 pull-right'>
   %include pagination_element navi=navi, app=app, page=page, div_class="pull-right"
   </div>
</div>

<hr/>

%if app.get_nb_problems() > 0 and page == 'problems' and app.play_sound:
   <EMBED src="/static/sound/alert.wav" autostart=true loop=false volume=100 hidden=true>
%end

<!-- Problems filtering and display -->
<div class="row" style="padding: 0px;">
   <!-- Left panel, toolbar and active filters -->
   <div id="toolbar" class="col-lg-3 col-md-4 col-sm-4">
      <!-- Perfdata panel -->
      <div class="panel panel-info" id="image_panel">
         <div class="panel-heading">Perfdatas</div>
         <div class="panel-body">
            <div id="img_hover"></div>
         </div>
      </div>

%if actions_allowed:
      <!-- Actions panel -->
      <div class="panel panel-info" id="actions">
         <div class="panel-heading">Actions</div>
         <div class="panel-body">
            <ul class="list-group">
               <li class="list-group-item" title="Try to fix all selected problems (launch event handler if defined)"><a href="javascript:try_to_fix_all();"><i class="fa fa-magic"></i> Try to fix</a></li>
               <li class="list-group-item" title="Launch the check command for all selected services"><a href="javascript:recheck_now_all()"><i class="fa fa-refresh"></i> Recheck</a></li>
               <li class="list-group-item" title="Force selected services to be considered as Ok"><a href="javascript:submit_check_ok_all()"><i class="fa fa-share"></i> Submit Result OK</a></li>
               <li class="list-group-item" title="Acknowledge all selected problems"><a href="javascript:acknowledge_all('{{user.get_name()}}')"><i class="fa fa-check"></i> Acknowledge</a></li>
               <li class="list-group-item" title="Schedule a one day downtime for all selected problems"><a href="javascript:downtime_all('{{user.get_name()}}')"><i class="fa fa-ambulance"></i> Schedule a downtime</a></li>
               <li class="list-group-item" title="Ignore checks for selected services (disable checks, notifications, event handlers and force Ok)"><a href="javascript:remove_all('{{user.get_name()}}')"><i class="fa fa-eraser"></i> Delete from WebUI</a></li>
            </ul>
         </div>
      </div>
%end
      <!-- Filters panel -->
      <div class="panel panel-info">
         <div class="panel-heading">Filtering</div>
         <div class="panel-body">
            <div class="btn-group btn-group-justified">
               <a href="#filtering" data-toggle="modal" data-target="#filtering" class="btn btn-success"><i class="fa fa-plus"></i> </a>
               <a id='remove_all_filters2' href='javascript:remove_all_current_filter("/{{page}}");' class="btn btn-danger"><i class="fa fa-minus"></i> </a>
            </div>

            %got_filters = sum([len(v) for (k,v) in filters.iteritems()]) > 0
            %if got_filters:
            <br/>
            <ul class="list-group">
            Active filters: 
            %for n in filters['hst_srv']:
            <li class="list-group-item">
              <span class="filter_color hst_srv_filter_color">&nbsp;</span>
              <span class="hst_srv_filter_name">Name: {{n}}</span>
              <span class="filter_delete"><a href='javascript:remove_current_filter("hst_srv", "{{n}}", "/{{page}}");' class="close">&times;</a></span>
            </li>
            <script>add_active_hst_srv_filter('{{n}}');</script>
            %end

            %for hg in filters['hg']:
            <li class="list-group-item">
              <span class="filter_color hg_filter_color">&nbsp;</span>
              <span class="hg_filter_name">Group: {{hg}}</span>
              <span class="filter_delete"><a href='javascript:remove_current_filter("hg", "{{hg}}", "/{{page}}");' class="close">&times;</a></span>
            </li>
            <script>add_active_hg_filter('{{hg}}');</script>
            %end

            %for r in filters['realm']:
            <li class="list-group-item">
              <span class="filter_color realm_filter_color">&nbsp;</span>
              <span class="realm_filter_name">Realm: {{r}}</span>
              <span class="filter_delete"><a href='javascript:remove_current_filter("realm", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
            </li>
            <script>add_active_realm_filter('{{r}}');</script>
            %end

            %for r in filters['htag']:
            <li class="list-group-item">
              <span class="filter_color tag_filter_color">&nbsp;</span>
              <span class="tag_filter_name">Tag: {{r}}</span>
              <span class="filter_delete"><a href='javascript:remove_current_filter("htag", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
            </li>
            <script>add_active_htag_filter('{{r}}');</script>
            %end

            %for r in filters['stag']:
            <li class="list-group-item">
              <span class="filter_color stag_filter_color">&nbsp;</span>
              <span class="stag_filter_name">Tag: {{r}}</span>
              <span class="filter_delete"><a href='javascript:remove_current_filter("stag", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
            </li>
            <script>add_active_stag_filter('{{r}}');</script>
            %end

            %for r in filters['ack']:
            <li class="list-group-item">
              <span class="filter_color ack_filter_color">&nbsp;</span>
              <span class="ack_filter_name">Ack: {{r}}</span>
              <span class="filter_delete"><a href='javascript:remove_current_filter("ack", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
            </li>
            <script>add_active_state_ack_filter('{{r}}');</script>
            %end

            %for r in filters['downtime']:
            <li class="list-group-item">
              <span class="filter_color downtime_filter_color">&nbsp;</span>
              <span class="downtime_filter_name">Downtime: {{r}}</span>
              <span class="filter_delete"><a href='javascript:remove_current_filter("downtime", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
            </li>
            <script>add_active_state_downtime_filter('{{r}}');</script>
            %end

            %for r in filters['crit']:
            <li class="list-group-item">
              <span class="filter_color criticity_filter_color">&nbsp;</span>
              <span class="criticity_filter_name">Criticity: {{r}}</span>
              <span class="filter_delete"><a href='javascript:remove_current_filter("crit", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
            </li>
            <script>add_active_state_criticity_filter('{{r}}');</script>
            %end
          </ul>
          
            <br/>
            <!-- Bookmarks creation -->
            <div class="btn-group btn-group-justified" role="group">
               <div class="btn-group btn-group-sm" role="group">
                  <button type="button" class="btn btn-primary btn-lg btn-block dropdown-toggle" data-toggle="dropdown" aria-expanded="true" id="dropdownMenu1"> <i class="fa fa-tags"></i> Bookmark the current filter</button>
                  <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
                     <li role="presentation">
                        <div style="padding: 15px; padding-bottom: 0px;">
                           <form class="form_in_dropdown" role="form" name='bookmark_save' id='bookmark_save'>
                              <div class="form-group">
                                 <label for="bookmark_name" class="control-label">Bookmark name</label>
                                 <input class="form-control input-sm" id="bookmark_name" name="bookmark_name" placeholder="..." aria-describedby="help_bookmark_name">
                                 <span id="help_bookmark_name" class="help-block">Use an identifier to create a bookmark referencing the current applied filters.</span>
                              </div>
                              <a class='btn btn-success' href='javascript:add_new_bookmark("/{{page}}");'> <i class="fa fa-save"></i> Save</a>
                           </form>
                        </div>
                     </li>
                  </ul>
               </div>
            </div>
            %end
         </div>
      </div>

      <!-- Bookmarks panel -->
      <div class="panel panel-info">
         <div class="panel-heading">Bookmarks</div>
         <div class="panel-body">
            <div id='bookmarks'></div>
            <div id='bookmarksro'></div>
         </div>
      </div>
   </div>

   <!-- Right panel, with all problems -->
   <div id="problems" class="col-lg-9 col-md-8 col-sm-8">

      %from itertools import groupby
      %pbs = sorted(pbs, key=lambda x: x.business_impact, reverse=True)
      %for business_impact, bi_pbs in groupby(pbs, key=lambda x: x.business_impact):
        <h3> Business impact: {{!helper.get_business_impact_text(business_impact)}} </h3>
      <table class="table table-bordered table-condensed table-striped">
        <thead><tr>
            <th align="center">Host</th>
            <th align="center">Service</th>
            <th align="center">State</th>
            <th align="center">Since</th>
            <th align="center">Last check</th>
            <th align="center">Next check</th>
            <th align="center">Output</th>
            %if actions_allowed:
            <th align="center">Actions</th>
            %end
        </tr></thead>

        <tbody>
        %bi_pbs = sorted(bi_pbs, key=lambda x: x.host_name)
        %for host_name, host_pbs in groupby(bi_pbs, key=lambda x: x.host_name):
        %for i, pb in enumerate(host_pbs):
            
         %# Host information ...
          <tr>
            <td>
              <div class="tick pull-left" style="cursor:pointer;" onclick="add_remove_elements('{{helper.get_html_id(pb)}}')">
                <img class='img_tick' id='selector-{{helper.get_html_id(pb)}}' src='/static/images/tick.png' />
              </div>
              %if i == 0:
              <a href="/host/{{pb.host_name}}">{{pb.host_name}}</a>
              %end
            </td>
            %if pb.__class__.my_type == 'service':
            <td>{{!helper.get_link(pb, short=True)}}</td>
            %else:
            <td></td>
            %end
            <td align="center" class="background-{{pb.state.lower()}}">{{ pb.state }}</td>
            <td>{{!helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}</td>
            <td>{{!helper.print_duration(pb.last_chk, just_duration=True, x_elts=2)}} ago</td>
            <td>in {{!helper.print_duration(pb.next_chk, just_duration=True, x_elts=2)}}</td>
            <td>{{ pb.output }}</td>
            %if actions_allowed:
            <td align="center" width="150px">
              <div class="btn-group" role="group" aria-label="...">
                <button type="button" class="btn btn-default btn-xs" title="Try to fix (launch event handler if defined)" onClick="try_to_fix_one('{{ pb.get_full_name() }}');">
                  <i class="fa fa-magic"></i>
                </button>
                <button type="button" class="btn btn-default btn-xs" title="Launch the check command " onClick="recheck_now_one('{{ pb.get_full_name() }}');">
                  <i class="fa fa-refresh"></i>
                </button>
                <button type="button" class="btn btn-default btn-xs" title="Force service to be considered as Ok" onClick="submit_check_ok_one('{{ pb.get_full_name() }}', '{{ user.get_name() }}');">
                  <i class="fa fa-share"></i>
                </button>
                <button type="button" class="btn btn-default btn-xs" title="Acknowledge the problem" onClick="acknowledge_one('{{ pb.get_full_name() }}', '{{ user.get_name() }}');">
                  <i class="fa fa-check"></i>
                </button>
                <button type="button" class="btn btn-default btn-xs" title="Schedule a one day downtime for the problem" onClick="downtime_one('{{ pb.get_full_name() }}', '{{ user.get_name() }}');">
                  <i class="fa fa-ambulance"></i>
                </button>
                <button type="button" class="btn btn-default btn-xs" title="Ignore checks for the service (disable checks, notifications, event handlers and force Ok)" onClick="remove_one('{{ pb.get_full_name() }}', '{{ user.get_name() }}');">
                  <i class="fa fa-eraser"></i>
                </button>
              </div>
            </td>
            %end
          </tr>

        %# End for pb in pbs:
        %end
        %end
        </tbody>
      </table>
      %end
         
      %# Close problems div ...
   </div>
  
  %include pagination_element navi=navi, app=app, page=page, div_class="pull-right"
</div>