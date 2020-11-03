<master src="../../intranet-core/www/master">
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>
<property name="main_navbar_label">user</property>
<property name="focus">@focus;literal@</property>

<!-- Show calendar on start- and end-date -->
<script type="text/javascript" <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>
window.addEventListener('load', function() { 
     document.getElementById('birthdate_calendar').addEventListener('click', function() { showCalendar('birthdate', 'y-m-d'); });
     document.getElementById('start_date_calendar').addEventListener('click', function() { showCalendar('start_date', 'y-m-d'); });
     document.getElementById('end_date_calendar').addEventListener('click', function() { showCalendar('end_date', 'y-m-d'); });
});
</script>

<h2>@page_title@</h2>
<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>
<formtemplate id="employee_information"></formtemplate>

