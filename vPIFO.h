# ifndef VPIFO_H
# define VPIFO_H

# include <fstream>
# include <sstream>
# include <iostream>
# include <map>
# include <memory>
# include "ns3/ipv4-queue-disc-item.h"
# include "ns3/ptr.h"
# include "ns3/tcp-header.h"
# include "ns3/Tenant-tag.h"
# include "MyPipeline.h"
# include "MyScheduling.h"

namespace ns3 {
    class vPIFO : public QueueDisc{
        public:
            vPIFO();
            
            static TypeId GetTypeId(void);

            bool DoEnqueue(Ptr<QueueDiscItem> item);        
            Ptr<QueueDiscItem> DoDequeue(void);
            Ptr<const QueueDiscItem> DoPeek(void) const;
            bool CheckConfig(void);
            void InitializeParams(void);
        
        private:
            // The index of root
            static const int ROOT;
            // The size of a queue
            static const int SIZE;

            std::unordered_map<string, int> flow_map;
            std::unordered_map<int, std::shared_ptr<Scheduling>> sch_tree;
            std::unordered_map<int, std::queue<Ptr<QueueDiscItem>>> queue_map;
            int queue_cnt = 1000;
            int size;

            Pipeline pipe;

            bool IsHadoop(int x);

            std::string GetFlowLabel(Ptr<QueueDiscItem> item); 
    };
}

# endif