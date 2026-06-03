import UIKit

enum InspectionPlanImageRenderer {
    private struct Row {
        let date: String
        let unit: String
        let contractor: String
        let phone: String
        let highlighted: Bool
    }

    static let image: UIImage = makeImage()

    private static let rows: [Row] = [
        Row(date: "1", unit: "东航技术武汉分公司", contractor: "", phone: "", highlighted: false),
        Row(date: "2", unit: "南航湖北维修基地", contractor: "", phone: "", highlighted: false),
        Row(date: "3", unit: "京维武汉分公司", contractor: "", phone: "", highlighted: false),
        Row(date: "4", unit: "机场公司地服（含机务、站坪、代理航司）", contractor: "", phone: "", highlighted: false),
        Row(date: "5", unit: "东航武汉公司地服", contractor: "龙略航服", phone: "", highlighted: false),
        Row(date: "6", unit: "东航实业公司", contractor: "", phone: "", highlighted: false),
        Row(date: "7", unit: "南航股份湖北分公司地服部（含外包单位）", contractor: "港玄科技--客舱清洁", phone: "", highlighted: false),
        Row(date: "8", unit: "国航股份湖北分公司地服部", contractor: "", phone: "", highlighted: false),
        Row(date: "9", unit: "东航食", contractor: "", phone: "", highlighted: false),
        Row(date: "10", unit: "南联航食", contractor: "", phone: "", highlighted: false),
        Row(date: "11", unit: "中航油", contractor: "", phone: "", highlighted: false),
        Row(date: "12", unit: "华南蓝天航油", contractor: "", phone: "", highlighted: false),
        Row(date: "13", unit: "空港航空物流公司", contractor: "", phone: "", highlighted: false),
        Row(date: "14", unit: "东航综管部", contractor: "机组车：", phone: "", highlighted: false),
        Row(date: "15", unit: "国航综保部", contractor: "机组车：刘经理", phone: "", highlighted: false),
        Row(date: "16", unit: "南航综保部", contractor: "机组车：姜山", phone: "", highlighted: false),
        Row(date: "17", unit: "厦门航空", contractor: "负责人：方站长", phone: "", highlighted: false),
        Row(date: "18", unit: "海南航空", contractor: "负责人：范站长", phone: "", highlighted: false),
        Row(date: "19", unit: "机场安全检查站", contractor: "", phone: "", highlighted: false),
        Row(date: "20", unit: "机场消防救护支队", contractor: "", phone: "", highlighted: false),
        Row(date: "21", unit: "机场动力能源保障部", contractor: "", phone: "", highlighted: false),
        Row(date: "22", unit: "商旅服务公司（要客、公务机摆渡与航班协调）", contractor: "", phone: "", highlighted: false),
        Row(date: "23", unit: "机场集团信科公司", contractor: "", phone: "", highlighted: false),
        Row(date: "24", unit: "机场集团建投公司", contractor: "", phone: "", highlighted: false),
        Row(date: "25", unit: "机场飞行区管理部", contractor: "", phone: "", highlighted: false),
        Row(date: "26", unit: "顺丰航空--由班组长与负责人沟通确定其进场作\n业具体时间，根据进场时间安排参加考试", contractor: "机务负责人：黄\n威", phone: "13570840319", highlighted: true),
        Row(date: "27", unit: "厦门太古机务--由班组长与负责人沟通确定其进\n场作业具体时间，根据进场时间安排参加考试", contractor: "负责人：苏站长", phone: "值班：13476857630", highlighted: true),
        Row(date: "28", unit: "邮政航空--由班组长与负责人沟通确定其进场作\n业具体时间，根据进场时间安排参加考试", contractor: "负责人：张站长", phone: "值班：18995579464", highlighted: true),
        Row(date: "", unit: "中原龙浩航空--由班组长与负责人沟通确定其进\n场作业具体时间，根据进场时间安排参加考试", contractor: "负责人：党站长", phone: "13392607415", highlighted: false)
    ]

    private static func makeImage() -> UIImage {
        let size = CGSize(width: 1024, height: 1317)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            drawHeader(in: context.cgContext)
            drawTable(in: context.cgContext)
        }
    }

    private static func drawHeader(in context: CGContext) {
        drawCentered("飞行区培训效果验证抽查计划", in: CGRect(x: 0, y: 6, width: 1024, height: 36), size: 23, weight: .regular)

        let intro = "测试地点：运行监管室值班室（（T3 航站楼机坪 301 机位旁,1B2-12），每\n日抽查2人。"
        drawText(intro, in: CGRect(x: 4, y: 52, width: 1008, height: 82), size: 25, weight: .regular)

        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        [1, 46, 137].forEach { y in
            context.move(to: CGPoint(x: 0, y: CGFloat(y)))
            context.addLine(to: CGPoint(x: 1024, y: CGFloat(y)))
        }
        context.strokePath()
    }

    private static func drawTable(in context: CGContext) {
        let xPositions: [CGFloat] = [0, 70, 584, 777, 1024]
        let headerY: CGFloat = 137
        let headerHeight: CGFloat = 39
        let standardRowHeight: CGFloat = 36
        let tallRowHeight: CGFloat = 69
        let lastRowHeight: CGFloat = 77

        var y = headerY
        drawGridLine(context, from: CGPoint(x: 0, y: y), to: CGPoint(x: 1024, y: y))
        y += headerHeight

        drawCentered("日期", in: CGRect(x: 0, y: headerY + 5, width: 70, height: 28), size: 22, weight: .semibold)
        drawCentered("单位（含相关外包单位）", in: CGRect(x: 70, y: headerY + 5, width: 514, height: 28), size: 22, weight: .semibold)
        drawCentered("外包单位名称1", in: CGRect(x: 584, y: headerY + 5, width: 193, height: 28), size: 22, weight: .semibold)
        drawCentered("联系电话", in: CGRect(x: 777, y: headerY + 5, width: 247, height: 28), size: 22, weight: .semibold)

        for row in rows {
            let rowHeight: CGFloat
            if row.date == "" {
                rowHeight = lastRowHeight
            } else if row.highlighted {
                rowHeight = tallRowHeight
            } else {
                rowHeight = standardRowHeight
            }

            if row.highlighted {
                UIColor.yellow.setFill()
                context.fill(CGRect(x: 70, y: y, width: 514, height: rowHeight))
            }

            drawCentered(row.date, in: CGRect(x: 0, y: y + 3, width: 70, height: min(32, rowHeight - 6)), size: 20, weight: .regular)
            drawText(row.unit, in: CGRect(x: 76, y: y + 4, width: 500, height: rowHeight - 8), size: 22, weight: .regular)
            drawText(row.contractor, in: CGRect(x: 588, y: y + 5, width: 181, height: rowHeight - 10), size: 20, weight: .regular)
            drawText(row.phone, in: CGRect(x: 783, y: y + 7, width: 235, height: rowHeight - 14), size: row.phone.hasPrefix("值班") ? 19 : 20, weight: .regular)

            drawGridLine(context, from: CGPoint(x: 0, y: y), to: CGPoint(x: 1024, y: y))
            y += rowHeight
        }

        drawGridLine(context, from: CGPoint(x: 0, y: y), to: CGPoint(x: 1024, y: y))
        for x in xPositions {
            drawGridLine(context, from: CGPoint(x: x, y: headerY), to: CGPoint(x: x, y: y))
        }
    }

    private static func drawGridLine(_ context: CGContext, from: CGPoint, to: CGPoint) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2)
        context.move(to: from)
        context.addLine(to: to)
        context.strokePath()
    }

    private static func drawCentered(_ text: String, in rect: CGRect, size: CGFloat, weight: UIFont.Weight) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        draw(text, in: rect, size: size, weight: weight, paragraph: paragraph)
    }

    private static func drawText(_ text: String, in rect: CGRect, size: CGFloat, weight: UIFont.Weight) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 2
        draw(text, in: rect, size: size, weight: weight, paragraph: paragraph)
    }

    private static func draw(
        _ text: String,
        in rect: CGRect,
        size: CGFloat,
        weight: UIFont.Weight,
        paragraph: NSParagraphStyle
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraph
        ]
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }
}
