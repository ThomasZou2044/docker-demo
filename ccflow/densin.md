CCFlow API 原理及实现
===========================
`CCFlow`的核心API代码基本的讲解在官方文档中并未涉及，只做了核心表的 [简介](https://gitee.com/opencc/JFlow/wikis/%E5%AE%89%E8%A3%85&%E9%9B%86%E6%88%90/%E6%95%B0%E6%8D%AE%E7%BB%93%E6%9E%84%E8%A1%A8/%E6%B5%81%E7%A8%8B%E6%A8%A1%E6%9D%BF%E8%A1%A8)，这里写一篇文章，对`CCFlow`核心API进行相关梳理 
# 目录
- [创建Flow模板流程](#创建flow模板流程)
- [保存Flow时的操作](#保存Flow时的操作)
- [Create Node的具体实现](#CreateNode的具体实现)
## 创建Flow模板流程 
创建Flow模板流程的过程比较简单，新建的模板只有两个默认节点，如下图所示
![new_nde.png](img/new_node.png)
### 新建Flow的流程如下
* 首先查询当前的Flow_Mark，`@FlowMark=d8` 是当前的Mark ID 用来校验是否已经存在当前Mark
```
Handler.ashx?DoType=Entities_Init&EnsName=BP.WF.Flows&Paras=@FlowMark=d8&t=1690421815756
```
* 第二步调用`Defualt_NewFlow`，传入下面的参数

![new_flow_param.png](img/new_flow_param.png)  
并在执行下面的方法
```C#
public string Defualt_NewFlow()
    {
        // 获取请求参数并处理
        int runModel = this.GetRequestValInt("RunModel");
        ......
        
        // NewFlow 方法 生成模板方法
        string flowNo = BP.WF.Template.TemplateGlo.NewFlow(FlowSort, FlowName,
                Template.DataStoreModel.SpecTable, PTable, FlowMark, FlowVersion);

        Flow fl = new Flow(flowNo);

        //清空WF_Emp 的StartFlows ,让其重新计算.
        DBAccess.RunSQL("UPDATE  WF_Emp Set StartFlows =''");
        return flowNo;
    }
```
其中的.TemplateGlo.NewFlow()方法会具体的执行生成新flow的方法，主要涉及
生成Flow 写入数据库，并且在此步骤中，创建Flow的默认Node 和 Directions（方向箭头）
```C#
// 创建Flow 包含创建Node
string flowNo = fl.DoNewFlow(flowSort, flowName, dsm, ptable, flowMark);
fl.No = flowNo;
fl.Retrieve();


//如果为CCFlow模式则不进行写入Json串
if (flowVer == "0")
    return flowNo;

//创建连线
Direction drToNode = new Direction();
drToNode.FK_Flow = flowNo;
drToNode.Node = int.Parse(int.Parse(flowNo) + "01");
drToNode.ToNode = int.Parse(int.Parse(flowNo) + "02");
drToNode.Insert();

// @liuqiang  增加方向.
Node nd = new Node(drToNode.Node);
nd.HisToNDs = drToNode.ToNode.ToString();
nd.Update();
```
`DoNewFlow`方法期中的主要操作包括 删除可能已经存在的历史Flow 新增Node
```c#
1. 先删除有可能存在的历史数据 再写入数据库
Flow fl = new Flow(this.No);
// 删除
fl.DoDelData();
fl.DoDelete();
// 删除后在保存
this.Save();

2. 新增Node
Node nd = new Node();
nd.NodeID = int.Parse(this.No + "01");
nd.Name = "Start Node";//  "开始节点"; 
nd.Step = 1;
......
nd.X = 200;
nd.Y = 150;
nd.NodePosType = NodePosType.Start;
nd.ICON = "フロント";
```
## 保存Flow时的操作
假设此时我们的流程结构如下图所示

![save_new.png](img/save_new.png)
  
那么此时点击保存按钮，浏览器会调用 Designer_Save 方法
这时候的参数，其中Node代表所有的节点， Dirs代表方向
```
Nodes: @1801,198,120@1802,200,250@1803,446,242@1804,446,132
Dirs: @018_1801_1802,018,1801,1802@018_1801_1804,018,1801,1804@018_1802_1803,018,1802,1803
```
当在`Designer_Save()`保存新规的节点时，具体的流程如下，首先是处理Node
```c#
// 保存节点位置. 假设我们的 参数中
// Nodes为Nodes: @1801,198,120@1802,200,250@1803,446,242@1804,446,132
string[] nodes = this.GetRequestVal("Nodes").Split('@');
// 此时对数组进行循环 [(1801,198,120),(1802,200,250).......]
foreach (string item in nodes)
{
    if (item == "" || item == null)
        continue;
    string[] strs = item.Split(',');
    // 1802 200 250 分别代表 Node Id 和X Y 坐标 
    sBuilder.Append("UPDATE WF_Node SET X=" + strs[1] + ",Y=" + strs[2] + " WHERE NodeID=" + strs[0] + ";");
}
```
其次处理Directions(箭头连线)
```
// 假设此时的Dirs参数 
// @018_1801_1802,018,1801,1802@018_1801_1804,018,1801,1804@018_1802_1803,018,1802,1803
sBuilder = new StringBuilder();
string[] dirs = this.GetRequestVal("Dirs").Split('@');
foreach (string item in dirs)
{
    if (item == "" || item == null)
        continue;
    string[] strs = item.Split(',');
    // 删除旧的数据 避免出错
    sBuilder.Append("DELETE FROM WF_Direction where MyPK='" + strs[0] + "';");
    // 018_1801_1802: 主键, 018:FlowID, 1801:FromNode, 1802:ToNode 
    sBuilder.Append("INSERT INTO WF_Direction(MyPK,FK_Flow,Node,ToNode,IsCanBack) values ('" + strs[0] + "','" + strs[1] + "','" + strs[2] + "','" + strs[3] + "'," + "0);");
}
// 运行SQL
DBAccess.RunSQLs(sBuilder.ToString());
```
## CreateNode的具体实现
当我们使用右键新规Node时

![new_node_menue.png](img/new_node_menue.png)

会调用Create_Node()方法，并且传入Node的相关参数
```
X: 145
Y: 412
FK_Flow: 018
```
后台收到请求后，会调用Create_Node()
```
public string CreateNode()
{
    string x = this.GetRequestVal("X");
    string y = this.GetRequestVal("Y");
    .......
    // 生成Node
    int nodeId = BP.WF.Template.TemplateGlo.NewNode(this.FK_Flow, iX, iY,icon);
    .......
}
```
在`BP.WF.Template.TemplateGlo.NewNode()`中，程序会调用`DoNewNode()`进行实际的新规操作
```
 public Node DoNewNode(int x, int y, string icon = null)
        {
            // 进行一些赋值操作
            Node nd = new Node();
            int idx = this.HisNodes.Count;
            ......
            
            // 实际插入
            nd.FWCVer = 1;
            nd.Insert();
            nd.CreateMap();
        }
```
在`nd.Insert();`中会根据系统的配置执行不同的数据库的SQL操作
```
  switch (SystemConfig.AppCenterDBType)
    {
        case DBType.MSSQL:
            return this.RunSQL(this.SQLCash.Insert, SqlBuilder.GenerParas(this, null));
        case DBType.Access:
            return this.RunSQL(this.SQLCash.Insert, SqlBuilder.GenerParas(this, null));
            break;
        case DBType.MySQL:
        case DBType.Informix:
        default:
            return this.RunSQL(this.SQLCash.Insert.Replace("[", "").Replace("]", ""), SqlBuilder.GenerParas(this, null));
    }
```
`this.SQLCash.Insert`中物理逻辑的表名是`WF_NODE`，是在系统启动后，在渲染GUI页面时会进行自动的注入，如下图所示

![1_table_name.png](img/1_table_name.png)

并且写入数据库操作完成之后会刷新缓存
```
// 开始更新内存数据。 @wangyanyan
if (this.EnMap.DepositaryOfEntity == Depositary.Application)
    Cash2019.PutRow(this.ToString(), this.PKVal.ToString(), this.Row);

this.afterInsert();
this.afterInsertUpdateAction();
```
## 获取工作流
通过`WF_DensinList`下的`GetDensinList`获取工作流数据接口，传入的参数`listType: 6;5;4`分别代表
```
public const string GET_MY_COMPLETE = "0";      　　　// 自分を見るの完了
public const string GET_MY_UNCOMPLETE = "1";    　　　// 自分を見るの未完了
public const string GET_MY_DIFFERENCE = "2";    　　　// 自分を見るの差戻
public const string GET_MY_DRAFT = "3";         　　　// 自分を見るの下書き
public const string GET_APPROVAL_COMPLETE = "4";      // 承認依頼を見るの完了
public const string GET_APPROVAL_UNCOMPLETE = "5";    // 承認依頼を見るの未完了
public const string GET_APPROVAL_INPROCESS = "6";     // 承認依頼を見るの処理待ち
```
首先会根据传入的参数进行不同的查询，这里我们用`承認依頼を見るの処理待ち`举例，此时会进入`GET_APPROVAL_INPROCESS`分支
```
 switch (listType[i])
    {
        // 自分を見るの完了一覧取得
        case GET_MY_COMPLETE:
            // 絞り込み条件作成
            selectKey = string.Format(" Starter = '{0}'", WebUser.No);
            //データ取得
            dtRtn = GetCompleteList(selectKey, COMPLETE_SORT_KEY,GET_MY_COMPLETE, btnNasiList);
            break;
        // 自分を見るの未完了
        case GET_MY_UNCOMPLETE:
            // 絞り込み条件作成
            selectKey = string.Format(" Starter = '{0}'", WebUser.No);
            //データ取得
            dtRtn = GetUnCompleteList(selectKey, COMPLETE_SORT_KEY,GET_MY_UNCOMPLETE, btnNasiList);
            break;
        // 自分を見るの差戻
        case GET_MY_DIFFERENCE:
            // 絞り込み条件作成
            selectKey = string.Format(" WFState = {0} AND Starter = '{1}'", WF_STATE_BACK, WebUser.No);
            //データ取得
            dtRtn = GetTodolist(selectKey, SORT_KEY,GET_MY_DIFFERENCE, btnNasiList);
            break;
        // 自分を見るの下書き
        case GET_MY_DRAFT:
            // 絞り込み条件作成
            selectKey = string.Format(" (WFState = {0} OR WFState = {1}) AND Starter = '{2}'", WF_STATE_DRAFT, WF_STATE_SINSEIZUMI, WebUser.No);
            //データ取得
            dtRtn = GetTodolist(selectKey, SORT_KEY,GET_MY_DRAFT, btnNasiList);
            break;
        // 承認依頼を見るの完了
        case GET_APPROVAL_COMPLETE:
            //絞り込み条件作成
            selectKey = string.Format(" Starter <> '{0}'", WebUser.No);
            //データ取得
            dtRtn = GetCompleteList(selectKey, SEND_DESC_SORT_KEY, GET_APPROVAL_COMPLETE, btnNasiList);
            break;
        // 承認依頼を見るの未完了
        case GET_APPROVAL_UNCOMPLETE:
            // 絞り込み条件作成
            selectKey = string.Format(" Starter <> '{0}' AND FK_Node > CurrNode", WebUser.No);
            //データ取得
            dtRtn = GetUnCompleteList(selectKey, COMPLETE_SORT_KEY, GET_APPROVAL_UNCOMPLETE, btnNasiList);
            break;
        // 承認依頼を見るの処理待ち
        case GET_APPROVAL_INPROCESS:
            // 絞り込み条件作成
            selectKey = string.Format(" (WFState = {0} OR WFState = {1}) AND Starter <> '{2}'", WF_STATE_SINSEIZUMI, WF_STATE_BACK, WebUser.No);
            //データ取得
            dtRtn = GetTodolist(selectKey, APPROVAL_WAITE_ASC_SORT_KEY, GET_APPROVAL_INPROCESS, btnNasiList);
            break;
    }
```
再调用`GetTodoList`
```
 string fk_node = this.GetRequestVal("FK_Node");
                string showWhat = this.GetRequestVal("ShowWhat");
                dt = SelectCommonDataTable(DB_GenerEmpWorksOfDataTable(WebUser.No, this.FK_Node, showWhat), selectKey, sort,type, btnNasiList);
```
方法在此方法中`DB_GenerEmpWorksOfDataTable()`会去查询当前的人员相关的flow数量
```
 if (fk_node == 0)
{
    ps.SQL = "SELECT A.* ,F.*,OU.ORDER_NUMBER FROM WF_EmpWorks A left join WF_Flow AS F on A.FK_Flow =F.No LEFT JOIN TT_WF_ORDER_NUMBER AS OU ON A.WorkID = OU.OID WHERE FK_Emp=" + dbstr + "FK_Emp AND TaskSta=0 AND " + wfStateSql + " ORDER BY  ADT DESC ";
    ps.Add("FK_Emp", userNo);
}
else
{
    ps.SQL = "SELECT A.* ,F.PTable ,OU.ORDER_NUMBER FROM WF_EmpWorks A left join WF_Flow AS F on A.FK_Flow =F.No LEFT JOIN TT_WF_ORDER_NUMBER AS OU ON A.WorkID = OU.OID WHERE FK_Emp=" + dbstr + "FK_Emp AND TaskSta=0 AND FK_Node=" + dbstr + "FK_Node  AND " + wfStateSql + " ORDER BY  ADT DESC ";
    ps.Add("FK_Node", fk_node);
    ps.Add("FK_Emp", userNo);
}
// 实际的SQL
SELECT A.* , F.*, OU.ORDER_NUMBER
FROM WF_EmpWorks A left join WF_Flow AS F on A.FK_Flow =F.No LEFT JOIN TT_WF_ORDER_NUMBER AS OU ON A.WorkID = OU.OID
WHERE FK_Emp=0210069 AND TaskSta=0 AND A.WFState!=10
ORDER BY  ADT DESC ;
```
其中的`WF_EmpWorks`是一个View表记录了用户和Work的一一对应的关系，我们需要的字段会在`SelectCommonDataTable()`中用到，在`SelectCommonDataTable`中我们使用
```
 public DataTable SelectCommonDataTable( DataTable dt ,string selectKey,string sort,string type, List<string> btnNasiList)
{
    StringBuilder logBuilder = new StringBuilder();

    // トランザクションテーブルSQL
    StringBuilder sqlsb = new StringBuilder();

    // トランザクションテーブル情報の取得
    int cnt = dt.Rows.Count;
    for (int i = 0; i < cnt; i++)
    {
        DataRow row = dt.Rows[i];
        sqlsb.Append("SELECT '");
        // 我们需要WorkID
        sqlsb.Append(row["WorkID"].ToString());
        sqlsb.Append("' as WorkID, SUMMRY, FlowStarter, FlowEnder FROM ");
        sqlsb.Append(row["PTable"].ToString());
        sqlsb.Append("  WHERE OID = ");
        sqlsb.Append(row["WorkID"].ToString());
        if (i == cnt - 1)
        {
            break;
        }
        sqlsb.Append(" union all ");
    }
    DataTable dtTran = DBAccess.RunSQLReturnTable(sqlsb.ToString());
    ......将查询出的数据进行处理，并返回前台
}


```
在SelectCommonDataTable()中，我们需要`WorkID`，`PTable`最后生成的SQL语句为
```
SELECT '143' as WorkID, SUMMRY, FlowStarter, FlowEnder
FROM TT_WF_ORDER
WHERE OID = 143
union all
SELECT '138' as WorkID, SUMMRY, FlowStarter, FlowEnder
FROM TT_WF_ORDER
WHERE OID = 138
union all
SELECT '126' as WorkID, SUMMRY, FlowStarter, FlowEnder
FROM TT_WF_ARRIVAL_RETURNS
WHERE OID = 126
union all
SELECT '122' as WorkID, SUMMRY, FlowStarter, FlowEnder
FROM TT_WF_ARRIVAL_RETURNS
WHERE OID = 122
```
最后将查询出的数据处理 并返回至前台即可

| workID | SUMMARY | FlowStarter | FlowEnder |
| ---------- | -----------|-----------|-----------|
| 143| {"AgentMode":"0","AutoApprovalMode":"N","content":[{"value":"真洲句　優祈音","name":"従業員氏名"},{"value":"0543956","name":"社員番号"},{"value":"イオンアイビス（株）","name":"会社名称"},{"value":"ＤＸシステム開発Ｇ","name":"所属"}]}	 | 0543956 | 0543956 |



