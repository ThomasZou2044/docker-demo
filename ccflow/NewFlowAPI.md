CCFlow 自定义API 实现
==============
`CCFlow`的核心API中，创建模板Flow的API只涉及两个初始节点，但是在本次项目的需求中，可能客户需要在GUI页面的时候
创建Flow的同时创建自定时的Node并且Node直接有方向箭头链接。因此，我们要在这个基础上进行二次修改。  
第二点就是创建Node的接口只能每次创建一个接口，没有在生成的Node直接进行连线我们也要进行自定义修改。

## 自定义创建CCFlow结论
参考之前的API， 我们需要进行修改，步骤如下：
1. 先调用之前的模板，创建一个模版Flow
```
 // 这一步一定要先登录
 Dev2Interface.Port_Login("0543956");
    string flowNo = BP.WF.Template.TemplateGlo.NewFlow(
            flowParam.FlowSort, 
            flowParam.FlowName, 
            BP.WF.Template.DataStoreModel.SpecTable, flowParam.PTable, 
            flowParam.FlowMark, 
            flowParam.FlowVersion);
```
2. 创建好Flow后，对Node进行修改，首先模板Flow自带两个Node，我们进需要进行名称修改，剩下的node需要进行新建
```
for (var i = 0; i < flowParam.Nodes.Count; i++)
{
    // 生成node id
    int k = i + 1;
    int nodeId = Convert.ToInt32(i < 10 ? int.Parse(flowNo) + "0" + k  : int.Parse(flowNo) + k);
    
    // 前两个node 只修改名称
    if (k <= 2)
    {
        
        WF_Admin_CCBPMDesigner.Node_DoEditNodeName(nodeId, flowParam.Nodes[i].NodeName);
        flowParam.Nodes[i].NodeId = nodeId;
    }
    else
    { 
        // 调用 create node 方法
        flowParam.Nodes[i].NodeId = CommonFlow.CreateNewNode(flowParam, flowParam.Nodes[i]);
    }

    // 设置方向 从 当前node 到下个 node
    if (i < flowParam.Nodes.Count - 1)
    {
        DirectionParam directionParam = new DirectionParam();
        directionParam.FlowNo = flowParam.FlowNo;
        directionParam.Node = flowParam.Nodes[i].NodeId;
        directionParam.ToNode = flowParam.Nodes[i].NodeId + 1;
        directionParam.IsCallBack = 0;
        directionParam.Id = $"{flowParam.FlowNo}_{directionParam.Node}_{directionParam.ToNode}";
        flowParam.Directions.Add(directionParam);
    }
}
```
3. 将上面设置的方向 写入数据库
```
CommonFlow.CreateDirections(flowParam);
```
进行上面的操作后，我们可以看到如下图，已经建立好了自定义的flow
![custom_flow.png](img%2Fcustom_flow.png)

## 修改Node（更新 删除）
在CCFlow原本的API中更新Node的方法只能一次进行单个node的更新，并且只能进行一种操作，因此我们
需要自定义API满足项目需求
```
public ActionResult CreateNode(FlowParam flowParam)
    {
        var result = flowParam.Nodes.Select(nodeItem =>
        {
            // 根据NodeID判断，id存贮是修改节点，id不存在就新增节点
            if (nodeItem.NodeId != 0)
            {
                CommonFlow.UpdateExistingNode(nodeItem);
            }
            else
            {
                CommonFlow.CreateNewNode(flowParam, nodeItem);
            }
            return nodeItem;
        }).ToList();
        // rest directions
        CommonFlow.GenerateDirections(flowParam);
        return Ok(result);
    }
```
### 参考
在公共类中写了自定义方法来进行CCFlow的修改
```

public class CommonFlow
{
    // 修改已存在的Node
    public static void UpdateExistingNode(NodeParam nodeItem)
    {
        // 判断Id 是否存在
        var node = new BP.WF.Node(nodeItem.NodeId);
        if (node.IsExits)
        {
            WF_Admin_CCBPMDesigner.Node_DoEditNodeName(nodeItem.NodeId, nodeItem.NodeName);
        }
    }

    // 创建Node 
    public static int CreateNewNode(FlowParam flowParam, NodeParam nodeItem)
    {
        var flow = new BP.WF.Flow(flowParam.FlowNo);
        // 判断Node存在性
        if (flow.IsExits)
        {
            // 先创建 再修改名称
            int nodeId = BP.WF.Template.TemplateGlo.NewNode(flowParam.FlowNo, nodeItem.X, nodeItem.Y, null);
            WF_Admin_CCBPMDesigner.Node_DoEditNodeName(nodeId, nodeItem.NodeName);
            return nodeId;
        }

        return 0;
    }
    
    // 创建节点之间的方向
    public static void CreateDirections(FlowParam flowParam)
    {
        StringBuilder sBuilder = new StringBuilder();
        foreach (DirectionParam item in flowParam.Directions)
        {
         
            // 统一先删除之前的在创建
            sBuilder.Append("DELETE FROM WF_Direction where MyPK='" + item.Id + "';");
            sBuilder.Append(
                $"INSERT INTO WF_Direction(MyPK,FK_Flow,Node,ToNode,IsCanBack) values ('{item.Id}','{item.FlowNo}','{item.Node}','{item.ToNode}','{item.IsCallBack}')");
        }
        DBAccess.RunSQLs(sBuilder.ToString());
    } 
    
    // 根据节点自动生成Direction
    public static void GenerateDirections(FlowParam flowParam)
    {
        var nodeList = new Nodes(flowParam.FlowNo).Tolist();
        StringBuilder sBuilder = new StringBuilder();
        // 从第二个节点开始生成
        for (int i = 1; i < nodeList.Count; i++)
        {
            int nodeId = nodeList[i - 1].NodeID;
            int toNodeId = nodeList[i].NodeID;
            string id = $"{flowParam.FlowNo}_{nodeId}_{toNodeId}";
            sBuilder.Append($"DELETE FROM WF_Direction where MyPK='{id}';");
            sBuilder.Append(
                $"INSERT INTO WF_Direction(MyPK,FK_Flow,Node,ToNode,IsCanBack) values ('{id}','{flowParam.FlowNo}','{nodeId}','{toNodeId}','0')");
        }
        DBAccess.RunSQLs(sBuilder.ToString());
    }
}
```