
## 属性

<style type="text/css">
.prop {
	background-color: rgba(226, 72, 16, 0.05);
	word-wrap: break-word;
	padding: 20px 10px;
}
.prop:nth-child(2n) {
    background-color: rgba(226, 72, 16, 0.08);
}
.hash-link {
    visibility: hidden;
}
h1:hover .hash-link, h2:hover .hash-link, h3:hover .hash-link, h4:hover .hash-link, h5:hover .hash-link, h6:hover .hash-link {
    visibility: visible;
}
</style>

{% for p in properties %}
{% if p.o2o != true %}
<div class="prop"><h4 class="propTitle" style="font-size:17px; font-weight: bold !important; margin-top:0; margin-bottom:0">{{ p.name }}</h4><div style="margin-top:-10px; margin-bottom: 5px;">
{% for e in p.enum %}
<span style="font-size:14px; font-family: Consolas,'Liberation Mono',Menlo,Courier,monospace; color:#888;background-color:white;padding:2px;">{{ e }}</span>
{% endfor %}
</div><div style="text-indent:2em">{{ p.desc }}</div></div>
{% endif %}
{% endfor %}


<!--{% for p in properties %}
- `{{ p.name }}`  
	{{ p.desc }}
{% endfor %}-->
