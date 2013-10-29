<%inherit file="base.mako"/>
<%def name="title()">Files</%def>
<%def name="content()">
<div mod-meta='{"tpl": "project/base.mako", "replace": true}'></div>

<% import website.settings %>

<form id="fileupload" action="${node_api_url + 'files/upload/'}" method="POST" enctype="multipart/form-data">
        <!-- The fileupload-buttonbar contains buttons to add/delete files and start/cancel the upload -->
        <div class="row fileupload-buttonbar">
            <div class="span7">
                <!-- The fileinput-button span is used to style the file input field as button -->
                <span class="btn btn-success fileinput-button${'' if user_can_edit else ' disabled'}">
                    <i class="icon-plus icon-white"></i>
                    <span>Add files...</span>
                    <input type="file" name="files[]" multiple>
                </span>
                <button type="submit" class="btn btn-primary start${'' if user_can_edit else ' disabled'}">
                    <i class="icon-upload icon-white"></i>
                    <span>Start upload</span>
                </button>
            </div>
            <!-- The global progress information -->
            <div class="span5 fileupload-progress fade">
                <!-- The global progress bar -->
                <div style='margin-bottom:0' class="progress progress-success progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100">
                    <div class="bar" style="width:0%;"></div>
                </div>
                <!-- The extended global progress information -->
                <div class="progress-extended">&nbsp;</div>
            </div>
        </div>
        <!-- The loading indicator is shown during file processing -->
        <div class="fileupload-loading"></div>
        <br>
        <!-- The table listing the files available for upload/download -->
        <div id='fileWidgetLoadingIndicator' class="progress progress-striped active">
            <div class="bar" style="width: 100%;">Loading...</div>
        </div>
        <table id='filesTable' role="presentation" class="table table-striped" style='display:none'>
            <thead>
                <tr>
                    <th>Filename</th>
                    <th>Date Modified</th>
                    <th>File Size</th>
                    <th colspan=2>Downloads</th>
                </tr>
            </thead>
            <tbody class="files">
            </tbody>
        </table>
</form>
<!-- The template to display files available for upload -->
<script id="template-upload" type="text/x-tmpl">
{% for (var i=0, file; file=o.files[i]; i++) { %}
    <tr class="template-upload fade">
        <td class="name"><span>{%=file.name%}</span></td>
        <td class="modified"><span></span></td>
        <td class="size"><span>{%=o.formatFileSize(file.size)%}</span></td>
        {% if (file.error) { %}
            <td class="error" colspan="2"><span class="label label-important">{%=locale.fileupload.error%}</span> {%=locale.fileupload.errors[file.error] || file.error%}</td>
        {% } else if (o.files.valid && !i) { %}
            <td colspan="2">
                <div class="progress progress-success progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0"><div class="bar" style="width:0%;"></div></div>
            </td>
            <td class="start">{% if (!o.options.autoUpload) { %}
                <button class="btn btn-primary">
                    <i class="icon-upload icon-white"></i>
                    <span>{%=locale.fileupload.start%}</span>
                </button>
            {% } %}</td>
        {% } else { %}
            <td colspan="2"></td>
        {% } %}
    </tr>
{% } %}
</script>
<!-- The template to display files available for download -->
<script id="template-download" type="text/x-tmpl">
{% for (var i=0, file; file=o.files[i]; i++) { %}
    <tr class="template-download fade">
        {% if (file.error) { %}
            <td class="name"><span>{%=file.name%}</span></td>
            <td></td>
            <td class="size"><span>{%=o.formatFileSize(file.size)%}</span></td>
            <td class="error" colspan="3"><span class="label label-important">{%=locale.fileupload.error%}</span> {%=locale.fileupload.errors[file.error] || file.error%}</td>
        {% } else { %}
            <td class="name">
                <a href="{%=file.url%}" title="{%=file.name%}">{%=file.name%}</a>
            </td>
            {% if (file.hasOwnProperty('action_taken') && file.action_taken === null) { %}
                    <td colspan=5>
                        <span class='label label-info'>No Action Taken</span> {%= file.message %}
                    </td>
            {% } else { %}
            <td>{%=file.date_uploaded%}</td>
            <td class="size"><span>{%=o.formatFileSize(file.size)%}</span></td>
            <td>{%=file.downloads%}</td>
            <td><a href="{%=file.download_url%}" download="{%=file.name%}"><i class="icon-download-alt"></i></a></td>
            <td><form class="fileDeleteForm" style="margin: 0;">
                % if user_can_edit:
                    <button type="button" class="btn btn-danger btn-delete delete-file" data-filename="{%=file.name%}" onclick="deleteFile(this)">
                        <i class="icon-trash icon-white"></i>
                        <span>Delete</span>
                    </button>
                % else:
                    <button type="button" class="btn btn-danger btn-delete disabled">
                        <i class="icon-trash icon-white"></i>
                        <span>Delete</span>
                    </button>
                % endif
            </form>
            </td>
            {% } %}
        {% } %}
    </tr>
{% } %}
</script>

<script type="text/javascript">
    function deleteFile(button) {
        var $button = $(button),
            filename = $button.attr('data-filename');
        bootbox.confirm(
            'Are you sure you want to delete the file "' + filename + '"?',
            function(result) {
                if (result) {
                    $.post(
                        '${node_api_url}files/delete/' + filename + '/'
                    ).always(function(response) {
                        if (response.status !== 'success') {
                            bootbox.alert('File could not be deleted');
                        } else {
                            $button.parents('.template-download').fadeOut();
                        }
                    });
                }
            }
        )
    }
</script>

<script>

$(function () {
    'use strict';

    // Initialize the jQuery File Upload widget:
    $('#fileupload').fileupload();
    $('#fileupload').fileupload('option',{
        url: '${node_api_url + 'files/upload/'}',
        acceptFileTypes: /(\.|\/)(.*)$/i,
        maxFileSize: ${website.settings.MAX_UPLOAD_SIZE}
    });

     // Load existing files:
     $('#fileupload').each(function () {
         var that = this;
         $.getJSON(this.action, function (result) {
             if (result && result.files.length) {
                 $(that).fileupload('option', 'done')
                     .call(that, null, {result: result.files});
             }
             $('#fileWidgetLoadingIndicator').fadeOut(400, function() {
                $('#filesTable').fadeIn(400)
             })

         });
     });
 });
</script>


<!-- The XDomainRequest Transport is included for cross-domain file deletion for IE8+ -->
<!--[if gte IE 8]><script src="/static/vendor/jquery-fileupload//js/cors/jquery.xdr-transport.js"></script><![endif]-->

% if not user_can_edit:
    <script type="text/javascript">
        $('.fileupload-buttonbar .btn').on('click', function(event) {
            event.preventDefault();
        });
        $('input[name="files[]"]').css('cursor', 'default');
    </script>
% endif
</%def>

<%def name="javascript()">
<script src="/static/vendor/jquery-ui-widget/jquery.ui.widget.js"></script>
<script src="/static/vendor/tmpl/tmpl.min.js"></script>
<script src="/static/vendor/jquery-fileupload/js/jquery.fileupload.js"></script>
<script src="/static/vendor/jquery-fileupload/js/load-image.min.js"></script>
<script src="/static/vendor/jquery-fileupload/js/canvas-to-blob.min.js"></script>
<script src="/static/vendor/jquery-fileupload/js/jquery.iframe-transport.js"></script>
<script src="/static/vendor/jquery-fileupload/js/jquery.fileupload-fp.js"></script>
<script src="/static/vendor/jquery-fileupload/js/jquery.fileupload-ui.js"></script>
<script src="/static/vendor/jquery-fileupload/js/locale.js"></script>
<script src="/static/vendor/bootstrap-image-gallery/bootstrap-image-gallery.min.js"></script>
</%def>