import 'dart:math';

import 'package:flutter/material.dart';
const distance = 80;
main(){
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Main(),
    );
  }
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  List<VirtualNode> nodes = [];
  List<VirtualEdge> edges = [];
  bool paintEnable = false;
  List<Offset> points = [];
  String? selectedId;
  List<Edge> inputEdge = [];
  Offset globalOffset = const Offset(0, 0);
  double x =300;
  double y = 300;
  @override
  void initState() {
buildGraph();
    super.initState();
  }
  Map<String,VirtualNode> nodesLocation = {};
  Map<String,VirtualEdge> edgesLocation = {};
  void buildGraph(){
    edges = [];
    edgesLocation.clear();
    for (var element in inputEdge) {
          Offset start = addNode(element.u).offset;
          Offset end = addNode(element.v).offset;
          VirtualEdge edge =  VirtualEdge(u: element.u, v: element.v, start: start, end: end,isWeight: false,weight: 10000);
          edges.add(edge);
          edgesLocation[edge.id] =edge;
          edgesLocation["${element.v} _ ${element.u}"] =edge;
    }
    setState(() {});
  }

  VirtualNode addNode(String id){
      if(nodesLocation.containsKey(id)) return nodesLocation[id]!;
      if(x > 300) {
        y+=distance;
        x = 50;
      } else {
        x +=distance;
      }
      Offset offset = Offset(x, y);
      VirtualNode newNode = VirtualNode(id: id, offset: offset, value: id);
      nodes.add(newNode);
      nodesLocation[id] = newNode;
      return newNode;
  }

  void select(DragDownDetails details){
    double xP = details.globalPosition.dx;
    double yP = details.globalPosition.dy;
    if(selectedId != null){
      nodesLocation[selectedId]?.isSelected = false;
      selectedId = null;
    }

    for(VirtualNode node in nodes){
      node.offset += globalOffset;
    }

    globalOffset = const Offset(0, 0);
    buildGraph();
    for(int i = nodes.length-1;i>=0;i--){
      double dx = xP - (nodes[i].offset.dx + 24);
      double dy = yP - (nodes[i].offset.dy + 24);
      double diff = sqrt(dx * dx + dy*dy);
      if(diff <= 24 && diff >= -24){
        selectedId = nodes[i].id;
        nodes[i].isSelected = true;
        break;
      }
    }
    setState(() {

    });
  }

  void drag(DragUpdateDetails details){
    if(paintEnable){
      points.add(details.localPosition);
      setState(() {

      });
      return;
    }
    if(selectedId != null){
      nodesLocation[selectedId]?.offset = details.globalPosition;
    }else{
      globalOffset += details.delta;
    }
    buildGraph();
  }

  void readInput(){
    String input = edgeInputController.text.trim();
    input = input.replaceAll("[", "");
    input = input.replaceAll("]", "");
    List<String> list = input.split(",");
    for(int i = 0;i<list.length;i+=2){
        inputEdge.add(Edge(u: list[i], v: list[i+1]));
    }
    edges = [];
    nodes = [];
    nodesLocation.clear();
    edgesLocation.clear();
     x =300;
    y = 300;
    buildGraph();
  }
  performDfs()async{
    List<Operation> operations = GraphAlgorithms.dfs(edges: inputEdge);
    Set<String> already = {};
    for(Operation op in operations){
      if(op.operationType == OperationType.edge){
        edgesLocation[op.id]?.color = Colors.red;
      }else{
        nodesLocation[op.id]?.color = Colors.tealAccent;
      }
      setState(() {

      });
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
  TextEditingController edgeInputController = TextEditingController(text: "[[0,1],[1,2],[1,3],[3,4],[3,5]]");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          backgroundColor: paintEnable ? Colors.black:Colors.teal,
          onPressed: (){
        setState(() {
          paintEnable = !paintEnable;
        });
        if(!paintEnable){
          points.clear();
          setState(() {});
        }
      },
          child: Icon(paintEnable?Icons.clear: Icons.brush)),
      appBar: AppBar(
        title: const Text("Graphvi"),
      ),
      body:
         Stack(
            children: [
              GestureDetector(
                onPanDown: select,
                onPanUpdate: drag,
                child: Container(
                  height: MediaQuery.of(context).size.height,
                 width: MediaQuery.of(context).size.width,
                  color: Colors.blueGrey.shade50,
                  child: CustomPaint(
                    painter: GraphWindow(nodes: nodes,edges: edges,globalOffset: globalOffset,points: points,paintEnable: paintEnable),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                height: MediaQuery.of(context).size.height-20,
                width: 340,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.shade200,
                      blurRadius: 20,
                    ),
                  ]
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10,),
                      const Text("Graph Options",style: TextStyle(color: Colors.black,fontSize: 22),),
                      const Divider(),
                      const Text("Edges ",style: TextStyle(color: Colors.black,fontSize: 16),),
                      TextField(
                        controller: edgeInputController,
                        maxLines: 20,
                        minLines: 5,
                        decoration: const InputDecoration(
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 8,),
                      ElevatedButton(onPressed: readInput, child: const Text("Generate Graph")),
                      ElevatedButton(onPressed: performDfs, child: const Text("DFS")),
                    ],
                  ),
                ),
              ),
            ],
          ),

    );
  }
}

class GraphWindow extends CustomPainter{
  GraphWindow({required this.edges, required this.nodes,required this.globalOffset,required this.paintEnable,required this.points});
  final List<VirtualNode> nodes;
  final List<VirtualEdge> edges;
  final bool paintEnable;
  final List<Offset> points;
  final Offset globalOffset;
  @override
  void paint(Canvas canvas, Size size) {
    if(paintEnable && points.isNotEmpty){
      Path path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      points.forEach((element) {
        path.lineTo(element.dx, element.dy);
      });
      canvas.drawPath(path, Paint()..color=Colors.teal..strokeWidth=4..style = PaintingStyle.stroke);
    }
    for (var edge in edges) {
      canvas.drawLine(edge.start + globalOffset, edge.end+globalOffset, Paint()..color=edge.color..strokeWidth = 3);
      if(edge.isWeight){
      double midX = min(edge.start.dx, edge.end.dx) +  max(edge.start.dx -edge.end.dx,edge.end.dx -edge.start.dx) / 2.0;
      double midY = min(edge.start.dy, edge.end.dy) +  max(edge.start.dy -edge.end.dy,edge.end.dy -edge.start.dy) / 2.0;
      TextSpan span = TextSpan(style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold), text: edge.weight.toString());
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(midX, midY-10) + globalOffset - const Offset(5, 5));
      // canvas.drawCircle(node.offset, 24, Paint()..color = node.color..style = PaintingStyle.fill);
    }
    }

    for (var node in nodes) {

      canvas.drawCircle(node.offset + globalOffset, 24, Paint()..color = node.isSelected ? Colors.blue:node.color..style = PaintingStyle.fill);
      TextSpan span = TextSpan(style: const TextStyle(color: Colors.black), text: node.value);
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, node.offset + globalOffset - const Offset(5, 5));
    }

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}
class VirtualNode{
  late String id;
  late Offset offset;
  late String value;
  late bool isSelected;
  late Color color;
  VirtualNode({required this.id,required this.offset,required this.value,this.color = Colors.amber,this.isSelected = false});
}
class VirtualEdge {
  late String u;
  late String v;
  late String id;
  late Offset start;
  late Offset end;
  late int weight;
  late bool isWeight;
  late bool isDirected;
  late Color color;
  VirtualEdge({required this.u,required this.v,required this.start,required this.end,this.isWeight = false,this.weight = 0,this.isDirected = false,this.color = Colors.green}){
    id = "$u _ $v";
  }
}
class Edge{
  late String u;
  late String v;
  late int weight;
  Edge({required this.u,required this.v,this.weight = 0});
}

class GraphAlgorithms{
  static List<Operation> dfs({required List<Edge> edges,List<int>? weight}){
    List<Operation> res = [];
    Map<String,List<String>> graph = {};
    for(Edge edge in edges){
      if(!graph.containsKey(edge.u)) graph[edge.u] = [];
      if(!graph.containsKey(edge.v)) graph[edge.v] = [];
      graph[edge.u]?.add(edge.v);
      graph[edge.v]?.add(edge.u);
    }
    _dfs("0", "-1", graph, {}, res);
    return res;
  }
  static void _dfs(String node,String parent,Map<String,List<String>> graph,Set<String> visited,List<Operation> res){
      if(parent != "-1") res.add( Operation(operationType: OperationType.edge, id: "$parent _ $node"));
      if(visited.contains(node)) return;
      visited.add(node);
      res.add(Operation(operationType: OperationType.node, id: node));
      if(!graph.containsKey(node)) return;
      for(String nbr in graph[node]!){
        if(nbr != parent){
          _dfs(nbr, node, graph, visited, res);
        }
      }

  }
}
class Operation{
  final OperationType operationType;
  final String id;
  const Operation({required this.operationType,required this.id});
}
enum OperationType{
  edge,
  node
}