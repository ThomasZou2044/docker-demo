CCFlow中GUI自定义实现
==============
首先我们自己的页面想要嵌入CCFlow的GUI必须要有一下步骤
### 在自己的html中引入`CCFlow Designer.html`
```
$(document).ready(function() {
    $("#btn-1").click(function (){
        $('#node-attr').modal('show');
    })
    $("#loadIframeButton").click(function() {
        // 创建一个 iframe 元素
        var iframe = $("<iframe>", {
            src: "Designer.htm?FK_Flow=002&UserNo=undefined&SID=undefined&Flow_V=0", // 设置 iframe 的 src 属性
            frameborder: 0, // 设置边框为 0，去掉边框
            width: "100%", // 设置宽度为 100%
            height: "400px" // 设置高度为 1000px
        });

        // 将 iframe 插入到容器中
        $("#iframeContainer").html(iframe);
    });
});
```
这样的话，刷新页面我们的GUI就会出现了
![gui_config.png](img%2Fgui_config.png)
### 如何自定义GUI画布中的右键菜单和自定义弹出框
#### 右键菜单
通过修改Html实现
![right_menu.png](img%2Fright_menu.png)```

#### 弹出框
在`Designer.html`引入的`Designer2018.js`中自定义节点属性
```
// 自定义对话框
<div id="alertModal6" style="width:300px;" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel"
         aria-hidden="true">
    <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">
            ×
        </button>
        <h4>
            ノード属性
        </h4>
    </div>
    <div class="modal-body">
        <input id ="name" placeholder="フォームURL" class="easyui-validatebox" type="text" name="name" data-options="required:true" />
    </div>
    <div class="modal-footer">
        <button style="float:left" class="btn btn-primary savetext" data-dismiss="modal" aria-hidden="true">
            ノードフォーム名の保存と更新
        </button>
    </div>
</div>

//节点属性
function NodeAttr(nodeID) {
    // 出发自定义窗口弹出
    $('#alertModal6').modal('toggle');
}
```
