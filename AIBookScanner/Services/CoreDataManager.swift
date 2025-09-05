import CoreData
import Foundation

/// CoreData管理器 - 负责本地数据存储和管理
class CoreDataManager {
    // 单例实例
    static let shared = CoreDataManager()

    // 持久化容器
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AIBookScanner")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("无法加载持久化存储: \(error.localizedDescription)")
            }
        }
        return container
    }()

    // 主上下文
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // 后台上下文
    func backgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    private init() {
        // 私有初始化方法
    }

    /// 初始化Core Data
    func initialize() {
        // 预加载操作（如果需要）
        print("Core Data初始化完成")
    }

    /// 保存上下文
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("上下文保存成功")
            } catch {
                let nsError = error as NSError
                print("保存上下文时出错: \(nsError), \(nsError.userInfo)")
                // 可以根据需要处理不同的错误类型
                handleCoreDataError(error)
            }
        }
    }

    /// 在后台保存上下文
    func saveBackgroundContext(_ context: NSManagedObjectContext) {
        context.perform {
            do {
                if context.hasChanges {
                    try context.save()
                    print("后台上下文保存成功")
                }
            } catch {
                print("保存后台上下文时出错: \(error.localizedDescription)")
                self.handleCoreDataError(error)
            }
        }
    }

    /// 处理Core Data错误
    private func handleCoreDataError(_ error: Error) {
        let nsError = error as NSError
        switch nsError.code {
        case NSManagedObjectConstraintMergeError:
            print("约束冲突错误: 可能存在重复数据")
        case NSManagedObjectValidationError:
            print("数据验证错误: 请检查输入数据的有效性")
        case NSPersistentStoreIncompatibleVersionHashError:
            print("数据模型版本不兼容")
        default:
            print("未知的Core Data错误: \(nsError)")
        }
    }

    /// 批量删除所有数据（用于测试或重置）
    func deleteAllData() {
        let context = backgroundContext()
        context.perform {
            let entities = self.persistentContainer.managedObjectModel.entities
            for entity in entities {
                if let entityName = entity.name {
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(
                        entityName: entityName)
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                    do {
                        try context.execute(deleteRequest)
                        print("已删除所有 \(entityName) 数据")
                    } catch {
                        print("删除 \(entityName) 数据时出错: \(error.localizedDescription)")
                    }
                }
            }

            // 保存更改
            self.saveBackgroundContext(context)
        }
    }

    /// 获取实体数量
    func countForEntity(_ entityName: String) -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        do {
            let count = try viewContext.count(for: fetchRequest)
            return count
        } catch {
            print("获取 \(entityName) 数量时出错: \(error.localizedDescription)")
            return 0
        }
    }

    /// 检查数据库是否为空
    func isDatabaseEmpty() -> Bool {
        let entities = persistentContainer.managedObjectModel.entities
        for entity in entities {
            if let entityName = entity.name, countForEntity(entityName) > 0 {
                return false
            }
        }
        return true
    }

    /// 导出数据库信息（用于调试）
    func exportDatabaseInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        let entities = persistentContainer.managedObjectModel.entities

        for entity in entities {
            if let entityName = entity.name {
                let count = countForEntity(entityName)
                info[entityName] = count
            }
        }

        return info
    }
}

// MARK: - 扩展功能

extension CoreDataManager {
    /// 执行批量操作
    func performBatchOperation(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = backgroundContext()
        context.perform {
            block(context)
            self.saveBackgroundContext(context)
        }
    }

    /// 异步获取数据
    func fetchAsync<T: NSManagedObject>(
        entityName: String,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        completion: @escaping ([T]) -> Void
    ) {
        let context = backgroundContext()
        context.perform {
            let fetchRequest = NSFetchRequest<T>(entityName: entityName)
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = sortDescriptors

            do {
                let results = try context.fetch(fetchRequest)
                // 切换到主线程返回结果
                DispatchQueue.main.async {
                    completion(results)
                }
            } catch {
                print("异步获取数据时出错: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }

    /// 检查实体是否存在
    func entityExists<T: NSManagedObject>(
        _ entity: T.Type,
        predicate: NSPredicate
    ) -> Bool {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1

        do {
            let count = try viewContext.count(for: fetchRequest)
            return count > 0
        } catch {
            print("检查实体是否存在时出错: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - 错误处理扩展

extension CoreDataManager {
    /// 重置数据库（危险操作，仅用于开发测试）
    func resetDatabase() {
        let storeCoordinator = persistentContainer.persistentStoreCoordinator
        for store in storeCoordinator.persistentStores {
            do {
                try storeCoordinator.destroyPersistentStore(
                    at: store.url!,
                    ofType: store.type,
                    options: nil
                )
                print("数据库已重置")
            } catch {
                print("重置数据库时出错: \(error.localizedDescription)")
            }
        }

        // 重新加载存储
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                print("重新加载存储时出错: \(error.localizedDescription)")
            }
        }
    }
}
