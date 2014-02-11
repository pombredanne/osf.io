<script type="text/html" id="s3_file_added">
added file
<a class="overflow" data-bind="text: params.path, click: function(){download(params.path);}"></a> to
bucket
<span data-bind="text: params.bucket"></span> in
<span data-bind="text: nodeCategory"></span>
<a class="log-node-title-link overflow" data-bind="attr: {href: nodeUrl}, text: nodeTitle"></a>
</script>

<script type="text/html" id="s3_file_updated">
updated file
<a class="overflow" data-bind="text: params.path"></a> to
bucket
<span data-bind="text: params.bucket"></span> in
<span data-bind="text: nodeCategory"></span>
<a class="log-node-title-link overflow" data-bind="attr: {href: nodeUrl}, text: nodeTitle"></a>
</script>

<script type="text/html" id="s3_file_removed">
removed file <span class="overflow" data-bind="text: params.path"></span> from
bucket
<span data-bind="text: params.bucket"></span> in
<span data-bind="text: nodeCategory"></span>
<a class="log-node-title-link overflow" data-bind="attr: {href: nodeUrl}, text: nodeTitle"></a>
</script>

<script type="text/javascript">
    function download(file)
    {
        $.ajax(
        {
            url:  nodeApiUrl + 's3/download/',
            type: 'POST',
            data: {'key': file},
            contentType: 'application/json',
            dataType: 'json'
        });
    };
</script>