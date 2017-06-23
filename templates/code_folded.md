<style>
  block { 
    display:block;
    overflow:scroll;
    max-height:0px;
    transition: max-height 300ms;
    -webkit-transition: max-height 300ms;
  }
  .display {
    max-height:500px;
  }
</style>

<script>
function toggleBlock(event) {
    block = event.target.parentNode.querySelector("block");
    if (block.className.indexOf("display") >= 0) {
      block.className = "";
    }
    else {
      block.className = "display";
    }
    event && event.preventDefault();
}
</script>
<div>
<a style="font-size:14px; cursor:pointer; display:inline-block; color:#E24810" onclick="toggleBlock(event)">
显示／隐藏代码
</a>

<block>
<pre class="editor" style="font-size:14px; line-height:1.3; margin:0;">{{ code | dump(2) }}</pre>
<img src style="display: none;" onerror="prepareEditor(event)"/>
</block>
</div>